# this file contains the local variables used in the Terraform configuration

locals {
  labels = {
    roles = {                # the label to determine the role of the server
      name   = "kube-role"   # the name of the label
      master = "kube-master" # the value for the master node
      worker = "kube-worker" # the value for the worker nodes
    }
  }

  ssh = {
    # even if some key is set as a "default" in the Hetzner Cloud UI, we need to provide the ID of the key
    # manually, because the API of the Hetzner Cloud ignores it
    owner-key-id = 7408734 # kot@kotobook, made manually using the Hetzner Cloud UI

    # customized SSH configuration for the servers (https://github.com/jtesta/ssh-audit)
    sshd-config = <<EOT
Port ${var.SSH_PORT}
PermitRootLogin prohibit-password
PasswordAuthentication no
X11Forwarding no
AllowAgentForwarding no
HostKeyAlgorithms ${join(",", var.SSHD_HOST_KEY_ALGORITHMS)}
KexAlgorithms ${join(",", var.SSHD_KEX_ALGORITHMS)}
Ciphers ${join(",", var.SSHD_CIPHERS)}
MACs ${join(",", var.SSHD_MACS)}
EOT
  }

  ips = {
    master-node = {
      private-ip = "10.0.1.254" # the private IP address of the "kube-master-node" server

      # since I wish to have a static IP address for the master node, I made it manually using the Hetzner Cloud UI
      primary-ips = {
        ipv4-id = 77527899 # "external-primary-ip-1-v4"
        ipv6-id = 77527991 # "external-primary-ip-1-v6"
      }
    }
  }

  k3s = {
    # the version of k3s to install on the servers
    version = "v1.31.4+k3s1" // https://github.com/k3s-io/k3s/releases
  }
}
