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
    ipv4 = local.ips.master-node.primary-ips.ipv4-id
    ipv6 = local.ips.master-node.primary-ips.ipv6-id
  }

  network {
    network_id = hcloud_network.kube-network.id
    ip         = local.ips.master-node.private-ip
  }

  # https://cloudinit.readthedocs.io/en/latest/index.html
  # changing those values will NOT affect the server, as they are used only for the cloud-init configuration
  user_data = format("#cloud-config\n%s", yamlencode({
    hostname                   = "kube-master-node" # set hostname
    timezone                   = "UTC"              # set timezone
    package_update             = true               # update package list
    package_upgrade            = true               # upgrade packages
    package_reboot_if_required = true               # reboot if required
    packages                   = ["curl", "ntp"]    # install packages
    users = [
      { # create a user for the k3s cluster
        name                = var.SSH_K3S_CLUSTER_USER
        gecos               = "k3s cluster user"
        shell               = "/bin/bash"
        ssh_authorized_keys = [var.SSH_K3S_CLUSTER_KEY_PUB]
        sudo                = ["ALL=(ALL) NOPASSWD:ALL"]
      }
    ]
    bootcmd = [ # run commands before the rest of the cloud-init configuration
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
      { # mute coredns import warnings
        path        = "/var/lib/rancher/k3s/server/manifests/coredns-config.yaml"
        permissions = "0600"
        owner       = "root:root"
        encoding    = "base64"
        content = base64encode(<<EOT
apiVersion: v1
kind: ConfigMap
metadata: {name: coredns-mute-import-warnings, namespace: kube-system}
data: # https://github.com/coredns/coredns/issues/3600
  empty.server: "# Empty server file to prevent import warnings"
  empty.override: "# Empty override file to prevent import warnings"
EOT
        )
      }
    ]
    runcmd = [
      # restart the SSH daemon to apply the new configuration
      "systemctl restart sshd",
      # change the mount point for the volume with persistent data
      "sed -i 's#/mnt/.*${local.volumes.master-node-id} #/mnt/persistent-volume #' /etc/fstab",
      # install cloud network auto-configuration package
      "curl -SsL https://packages.hetzner.com/hcloud/deb/hc-utils_0.0.6-1_all.deb -o /tmp/hc-utils.deb",
      "apt install -y /tmp/hc-utils.deb",
      "rm /tmp/hc-utils.deb",
      # install k3s (https://docs.k3s.io/reference/env-variables)
      join(" ", [ # we need to start the k3s service after the installation to create the token
        "curl -sfL 'https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/${local.k3s.version}/install.sh' | ",
        "INSTALL_K3S_VERSION='${local.k3s.version}'", # specify the version to install
        "K3S_TOKEN='${var.K3S_TOKEN}'",               # specify the token to use
        "INSTALL_K3S_SKIP_START=true",                # we will reboot the server after the installation
        format("INSTALL_K3S_EXEC='%s'", join(" ", [
          "--disable=traefik", # disable the built-in Traefik
          "--tls-san=kube.iddqd.uk",
          "--node-label=node/role=master",
          "--node-label=node/accept-external-traffic=true",
          "--node-ip=${local.ips.master-node.private-ip}",
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
    packages                   = ["curl", "ntp"]                # install packages
    users = [
      { # create a user for the k3s cluster
        name                = var.SSH_K3S_CLUSTER_USER
        gecos               = "k3s cluster user"
        shell               = "/bin/bash"
        ssh_authorized_keys = [var.SSH_K3S_CLUSTER_KEY_PUB]
        sudo                = ["ALL=(ALL) NOPASSWD:ALL"]
      }
    ]
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
      # install k3s
      join(" ", [
        "curl -sfL 'https://raw.githubusercontent.com/k3s-io/k3s/refs/tags/${local.k3s.version}/install.sh' | ",
        "INSTALL_K3S_SKIP_START=true",                # we will reboot the server after the installation
        "INSTALL_K3S_VERSION='${local.k3s.version}'", # specify the version to install
        "K3S_URL='https://${local.ips.master-node.private-ip}:6443'",
        "K3S_TOKEN='${var.K3S_TOKEN}'",
        format("INSTALL_K3S_EXEC='%s'", join(" ", [
          "--node-label=node/role=worker",
          "--node-ip=${each.value.private_ip}",
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
    hcloud_firewall.kube-firewall-workers,
    hcloud_server.kube-master-node,
  ]
}
