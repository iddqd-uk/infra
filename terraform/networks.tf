# This file is responsible for creating networks and subnets

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network
resource "hcloud_network" "kube-network" {
  # for the future, to have multiple servers in the same network
  name     = "kube-private-network"
  ip_range = "10.0.0.0/16"
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/primary_ip
data "hcloud_primary_ip" "master-node-primary-ipv4" {
  id = local.ips.master-node.primary-ips.ipv4-id
}

data "hcloud_primary_ip" "master-node-primary-ipv6" {
  id = local.ips.master-node.primary-ips.ipv6-id
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet
resource "hcloud_network_subnet" "kube-network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.kube-network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"

  depends_on = [hcloud_network.kube-network]
}
