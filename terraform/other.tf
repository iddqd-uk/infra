# additional resources

# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group
resource "hcloud_placement_group" "kube-placement-group" {
  name = "kube-placement-group"
  type = "spread"
}
