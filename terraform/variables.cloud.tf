# Terraform Cloud UI to manage variables: https://app.terraform.io/app/iddqd-uk/workspaces/infra/variables

variable "HTTP_PROXY_PORT" {
  description = "HTTP proxy port"
  type        = number
  sensitive   = true

  validation {
    condition     = var.HTTP_PROXY_PORT > 0 && var.HTTP_PROXY_PORT < 65536
    error_message = "Please provide a valid HTTP proxy port"
  }
}

variable "K3S_TOKEN" {
  description = "The server token is used to join both server and agent nodes to the cluster"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.K3S_TOKEN) > 8
    error_message = "Please provide a valid K3s token"
  }
}

variable "SSH_PORT" {
  description = "SSH port"
  type        = number
  sensitive   = true

  validation {
    condition     = var.SSH_PORT > 0 && var.SSH_PORT < 65536
    error_message = "Please provide a valid SSH port"
  }
}
