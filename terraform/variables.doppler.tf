# this file contains secrets, managed by the Doppler CLI. they are injected into the Terraform runtime via the
# `doppler run --name-transformer tf-var -- terraform ...` command, so doppler secret "FOO_BAR" becomes environment
# variable "TF_VAR_foo_bar" in the Terraform runtime, and accessible via the `var.foo_bar` syntax in the Terraform

variable "hetzner_cloud_api_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.hetzner_cloud_api_token) == 64
    error_message = "Please provide a valid Hetzner Cloud API token"
  }
}
