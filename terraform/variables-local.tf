# this file contains the local variables used in the Terraform configuration

locals {
  labels = {
    roles = {                # the label to determine the role of the server
      name   = "kube-role"   # the name of the label
      master = "kube-master" # the value for the master node
      worker = "kube-worker" # the value for the worker nodes
    }
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

  volumes = {
    # the ID of the "kube-master-node-volume-1" volume that is attached to the "kube-master-node" server
    master-node-id = 101899154
  }

  k3s = {
    # the version of k3s to install on the servers
    version = "v1.32.0+k3s1" // https://github.com/k3s-io/k3s/releases
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
HostKeyAlgorithms ${join(",", [
    "ssh-ed25519-cert-v01@openssh.com",
    "ssh-rsa-cert-v01@openssh.com",
    "ssh-ed25519",
    "rsa-sha2-256",
    "rsa-sha2-512",
    ])}
KexAlgorithms ${join(",", [
    "curve25519-sha256",
    "curve25519-sha256@libssh.org",
    "diffie-hellman-group18-sha512",
    "diffie-hellman-group14-sha256",
    "diffie-hellman-group16-sha512",
    "diffie-hellman-group-exchange-sha256",
    ])}
Ciphers ${join(",", [
    "chacha20-poly1305@openssh.com",
    "aes256-gcm@openssh.com",
    "aes128-gcm@openssh.com",
    "aes256-ctr",
    "aes192-ctr",
    "aes128-ctr",
    ])}
MACs ${join(",", [
    "hmac-sha2-512-etm@openssh.com",
    "hmac-sha2-256-etm@openssh.com",
    "umac-128-etm@openssh.com"
])}
EOT
}
}
