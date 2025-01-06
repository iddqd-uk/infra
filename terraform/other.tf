# additional resources

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group
resource "hcloud_placement_group" "kube-placement-group" {
  name = "kube-placement-group"
  type = "spread"
}

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/volume_attachment
resource "hcloud_volume_attachment" "kube-master-node-volume-1" {
  volume_id = local.volumes.master-node-id
  server_id = hcloud_server.kube-master-node.id
  automount = true

  lifecycle {
    ignore_changes = [server_id]
  }

  depends_on = [
    hcloud_server.kube-master-node,
  ]
}
