# this file holds the main resources, such as server, firewalls, networks, etc (main entry point)

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network
resource "hcloud_network" "main-network" {
  # for the future, to have multiple servers in the same network
  name     = "main-private-network"
  ip_range = "10.0.0.0/16"
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet
resource "hcloud_network_subnet" "main-network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.main-network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"

  depends_on = [hcloud_network.main-network]
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
resource "hcloud_firewall" "main-firewall" {
  name = "main-firewall"

  rule {
    description = "ssh"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = tostring(var.SSH_PORT)
  }

  rule {
    description = "http"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = "80"
  }

  rule {
    description = "https/tcp"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = "443"
  }

  rule {
    description = "https/udp"
    direction   = "in"
    protocol    = "udp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = "443"
  }

  rule {
    description = "http-proxy"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = tostring(var.HTTP_PROXY_PORT)
  }

  rule {
    description = "icmp"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group
resource "hcloud_placement_group" "main-placement-group" {
  name = "main-placement-group"
  type = "spread"
}

locals {
  # https://cloudinit.readthedocs.io/en/latest/index.html
  # changing those values will NOT affect the server, as they are used only for the cloud-init configuration
  main-1-cloud-init-config = {
    hostname                   = "iddqd-uk-main-1" # set hostname
    timezone                   = "UTC"             # set timezone
    package_update             = true              # update package list
    package_upgrade            = true              # upgrade packages
    package_reboot_if_required = true              # reboot if required
    packages                   = ["curl", "ntp"]   # install packages
    users = [
      {
        # this user will be used to deploy applications using ssh + docker. to deploy, add the PRIVATE key file path
        # to the ssh-agent (~/.ssh/config):
        #
        #   Host <server-ip-or-domain>
        #     IdentityFile ~/.ssh/ssh_infra@iddqd.uk
        #
        # and then use the following command to connect to the server:
        #
        #   DOCKER_HOST=ssh://<deploy-user>@<server-ip-or-domain>:<ssh-port> docker run hello-world
        name                = var.SSH_DEPLOY_USER
        gecos               = "Docker Deploy"
        shell               = "/bin/bash"
        ssh_authorized_keys = [var.SSH_DEPLOY_KEY_PUB]
      }
    ]
    write_files = [
      # customise SSH configuration (https://github.com/jtesta/ssh-audit)
      {
        path        = "/etc/ssh/sshd_config.d/cloudinit.conf"
        permissions = "0644"
        owner       = "root:root"
        content     = <<EOT
Port ${var.SSH_PORT}
PermitRootLogin prohibit-password
PasswordAuthentication no
HostKeyAlgorithms ${join(",", var.SSHD_HOST_KEY_ALGORITHMS)}
KexAlgorithms ${join(",", var.SSHD_KEX_ALGORITHMS)}
Ciphers ${join(",", var.SSHD_CIPHERS)}
MACs ${join(",", var.SSHD_MACS)}
EOT
      },
    ]
    runcmd = [
      "systemctl restart sshd",
      "wget -qO- https://get.docker.com | sh",
      format("usermod -aG docker %s", var.SSH_DEPLOY_USER), # allow deploy user to use docker without sudo
    ]
    power_state = {
      mode    = "reboot" # reboot once cloud-init is done
      message = "Rebooting after cloud-init"
    }
  }

  # the private IP address of the "main-1" server
  main-1-private-ip = "10.0.1.1"
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server
resource "hcloud_server" "server-main-1" {
  name        = "main-1"
  image       = "debian-12"
  server_type = "cx32"
  datacenter  = "nbg1-dc3" # hel1-dc2 (Helsinki) | fsn1-dc14 (Falkenstein) | ash-dc1 (Ashburn) | hil-dc1 (Hillsboro)

  ssh_keys           = [7408734] # kot@kotobook, made manually using the Hetzner Cloud UI (used as default)
  firewall_ids       = [hcloud_firewall.main-firewall.id]
  placement_group_id = hcloud_placement_group.main-placement-group.id

  backups                  = false
  shutdown_before_deletion = true

  public_net {
    ipv4 = 77527899 # "main-primary-ip-v4", made manually using the Hetzner Cloud UI
    ipv6 = 77527991 # "main-primary-ip-v6", made manually using the Hetzner Cloud UI
  }

  network {
    network_id = hcloud_network.main-network.id
    ip         = local.main-1-private-ip
  }

  user_data = format("#cloud-config\n%s", yamlencode(local.main-1-cloud-init-config))

  lifecycle {
    ignore_changes = [ssh_keys]
  }

  depends_on = [
    hcloud_firewall.main-firewall,
    hcloud_placement_group.main-placement-group,
    hcloud_network_subnet.main-network-subnet
  ]
}
