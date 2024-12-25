# this file describes the firewall configurations

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
resource "hcloud_firewall" "kube-firewall-master" {
  name = "kube-firewall-master"

  apply_to { # will be applied to the master node because it has the same label
    label_selector = format("%s=%s", local.labels.roles.name, local.labels.roles.master)
  }

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
    description = "k8s-api"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = "6443"
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

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall
resource "hcloud_firewall" "kube-firewall-workers" {
  name = "kube-firewall-workers"

  apply_to { # will be applied to the all worker nodes because they have the same label
    label_selector = format("%s=%s", local.labels.roles.name, local.labels.roles.worker)
  }

  rule {
    description = "ssh"
    direction   = "in"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    port        = tostring(var.SSH_PORT)
  }

  rule {
    description = "icmp"
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}
