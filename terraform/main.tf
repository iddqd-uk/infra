# this file holds the configuration for the servers

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
resource "hcloud_server" "kube-master-node" {
  name        = "kube-master-node"
  image       = "debian-12"
  server_type = "cx32"
  datacenter  = "nbg1-dc3" # hel1-dc2 (Helsinki) | fsn1-dc14 (Falkenstein) | ash-dc1 (Ashburn) | hil-dc1 (Hillsboro)

  ssh_keys           = [local.ssh.owner-key-id]
  placement_group_id = hcloud_placement_group.kube-placement-group.id
  labels             = { (local.labels.roles.name) : local.labels.roles.master }

  backups                  = false
  shutdown_before_deletion = true

  public_net {
    ipv4 = data.hcloud_primary_ip.master-node-primary-ipv4.id
    ipv6 = data.hcloud_primary_ip.master-node-primary-ipv6.id
  }

  network {
    network_id = hcloud_network.kube-network.id
    ip         = local.ips.master-node.private-ip
  }

  # https://cloudinit.readthedocs.io/en/latest/index.html
  # changing those values will NOT affect the server, as they are used only for the cloud-init configuration
  user_data = format("#cloud-config\n%s", yamlencode({
    hostname                   = "kube-master-node"                   # set hostname
    timezone                   = "UTC"                                # set timezone
    package_update             = true                                 # update package list
    package_upgrade            = true                                 # upgrade packages
    package_reboot_if_required = true                                 # reboot if required
    packages                   = ["curl", "ntp", "nfs-kernel-server"] # install packages
    bootcmd = [
      ["cloud-init-per", "once", "mkdir", "-m", "0700", "-p", "/var/lib/rancher/k3s/server/manifests"]
    ]
    write_files = [
      { # customise SSH configuration
        path        = "/etc/ssh/sshd_config.d/cloudinit.conf"
        permissions = "0644"
        owner       = "root:root"
        encoding    = "base64"
        content     = base64encode(local.ssh.sshd-config)
      },
      { # mute coredns import warnings (https://github.com/coredns/coredns/issues/3600)
        path        = "/var/lib/rancher/k3s/server/manifests/coredns-config.yaml"
        permissions = "0600"
        owner       = "root:root"
        encoding    = "base64"
        content = base64encode(<<EOT
apiVersion: v1
kind: ConfigMap
metadata: {name: coredns-custom, namespace: kube-system}
data:
  empty.server: |
    # Empty server file to prevent import warnings
  empty.override: |
    # Empty override file to prevent import warnings
EOT
        )
      }
    ]
    runcmd = [
      # restart the SSH daemon to apply the new configuration
      "systemctl restart sshd",
      # install cloud network auto-configuration package
      "curl -SsL https://packages.hetzner.com/hcloud/deb/hc-utils_0.0.6-1_all.deb -o /tmp/hc-utils.deb",
      "apt install -y /tmp/hc-utils.deb",
      "rm /tmp/hc-utils.deb",
      # change the mount point for the volume with persistent data
      "sed -i 's#/mnt/.*${local.volumes.master-node-id} #/mnt/persistent-volume #' /etc/fstab",
      # prepare the nfs mount point for the volume with persistent data
      "mkdir -p /mnt/persistent-volume",
      "chown -R nobody:nogroup /mnt/persistent-volume",
      "chmod 755 /mnt/persistent-volume",
      "echo '/mnt/persistent-volume 10.0.1.0/24(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports",
      "exportfs -a",
      # determine the private network interface for Flannel
      "export PRIVATE_NET_IFACE=$(ip -o -4 addr show | awk '/10\\.0\\.1\\./ {print $2}')",
      # install k3s (https://docs.k3s.io/reference/env-variables)
      join(" ", [ # we need to start the k3s service after the installation to create the token
        "curl -sfL 'https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/${local.k3s.version}/install.sh' | ",
        "INSTALL_K3S_VERSION='${local.k3s.version}'", # specify the version to install
        "K3S_TOKEN='${var.K3S_TOKEN}'",               # specify the token to use
        "INSTALL_K3S_SKIP_START=true",                # we will reboot the server after the installation
        format("INSTALL_K3S_EXEC=\"%s\"", join(" ", [
          "--disable=traefik", # disable the built-in Traefik
          "--tls-san=kube.iddqd.uk",
          "--node-label=node/role=master",
          "--node-label=node/accept-external-traffic=true",
          "--node-label=node/persistent-volume-mounted=true",
          "--node-ip=${local.ips.master-node.private-ip}",
          "--advertise-address=${local.ips.master-node.private-ip}",
          "--node-external-ip=${data.hcloud_primary_ip.master-node-primary-ipv4.ip_address}",
          "--flannel-iface=$PRIVATE_NET_IFACE",
        ])),
        "sh -s -",
      ]),
    ]
    power_state = {
      mode    = "reboot" # reboot once cloud-init is done
      message = "Rebooting after cloud-init"
    }
  }))

  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }

  depends_on = [
    hcloud_placement_group.kube-placement-group,
    hcloud_network_subnet.kube-network-subnet,
    hcloud_firewall.kube-firewall-master,
  ]
}

variable "worker-nodes" {
  description = "List of worker nodes to create"
  type = list(object({
    id          = number
    server_type = string
    private_ip  = string
  }))

  # add more servers to the list to create more worker nodes (id must be unique forever). in case of removing a server,
  # the id must not be reused, and node MUST BE drained and removed from the cluster before destroying the server
  default = [
    { id = 1, server_type = "cx22", private_ip = "10.0.1.1" },
  ]
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
resource "hcloud_server" "kube-worker-nodes" {
  for_each = { for r in var.worker-nodes : r.id => r }

  name        = "kube-worker-node-${each.key}"
  image       = "debian-12"
  server_type = each.value.server_type
  datacenter  = "nbg1-dc3"

  ssh_keys           = [local.ssh.owner-key-id]
  placement_group_id = hcloud_placement_group.kube-placement-group.id
  labels             = { (local.labels.roles.name) : local.labels.roles.worker }

  backups                  = false
  shutdown_before_deletion = true

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  network {
    network_id = hcloud_network.kube-network.id
    ip         = each.value.private_ip
  }

  # https://cloudinit.readthedocs.io/en/latest/index.html
  # changing those values will NOT affect the server, as they are used only for the cloud-init configuration
  user_data = format("#cloud-config\n%s", yamlencode({
    hostname                   = "kube-worker-node-${each.key}" # set hostname
    timezone                   = "UTC"                          # set timezone
    package_update             = true                           # update package list
    package_upgrade            = true                           # upgrade packages
    package_reboot_if_required = true                           # reboot if required
    packages                   = ["curl", "ntp", "nfs-common"]  # install packages
    write_files = [
      { # customise SSH configuration
        path        = "/etc/ssh/sshd_config.d/cloudinit.conf"
        permissions = "0644"
        owner       = "root:root"
        encoding    = "base64"
        content     = base64encode(local.ssh.sshd-config)
      }
    ]
    runcmd = [
      # restart the SSH daemon to apply the new configuration
      "systemctl restart sshd",
      # install cloud network auto-configuration package
      "curl -SsL https://packages.hetzner.com/hcloud/deb/hc-utils_0.0.6-1_all.deb -o /tmp/hc-utils.deb",
      "apt install -y /tmp/hc-utils.deb",
      "rm /tmp/hc-utils.deb",
      # wait for the master node to be ready
      "until curl -k 'https://${local.ips.master-node.private-ip}:6443'; do echo 'wait for master..'; sleep 1; done",
      # determine the private network interface for Flannel
      "export PRIVATE_NET_IFACE=$(ip -o -4 addr show | awk '/10\\.0\\.1\\./ {print $2}')",
      # install k3s
      join(" ", [
        "curl -sfL 'https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/${local.k3s.version}/install.sh' | ",
        "INSTALL_K3S_SKIP_START=true",                # we will reboot the server after the installation
        "INSTALL_K3S_VERSION='${local.k3s.version}'", # specify the version to install
        "K3S_URL='https://${local.ips.master-node.private-ip}:6443'",
        "K3S_TOKEN='${var.K3S_TOKEN}'",
        format("INSTALL_K3S_EXEC=\"%s\"", join(" ", [
          "--node-label=node/role=worker",
          "--node-label=node/persistent-volume-mounted=true",
          "--node-ip=${each.value.private_ip}",
          "--flannel-iface=$PRIVATE_NET_IFACE",
        ])),
        "sh -s -",
      ]),
      # configure the NFS client (do it after the k3s installation to avoid issues with inaccessibility NFS server)
      "mkdir -p /mnt/persistent-volume",
      "chown -R nobody:nogroup /mnt/persistent-volume",
      "chmod 755 /mnt/persistent-volume",
      "echo '${local.ips.master-node.private-ip}:/mnt/persistent-volume /mnt/persistent-volume nfs defaults 0 0' >> /etc/fstab",
    ]
    power_state = {
      mode    = "reboot" # reboot once cloud-init is done
      message = "Rebooting after cloud-init"
    }
  }))

  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }

  depends_on = [
    hcloud_placement_group.kube-placement-group,
    hcloud_network_subnet.kube-network-subnet,
    hcloud_firewall.kube-firewall-workers,
    hcloud_server.kube-master-node,
  ]
}
