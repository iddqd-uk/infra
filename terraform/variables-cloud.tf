# Terraform Cloud UI to manage variables: https://app.terraform.io/app/iddqd-uk/workspaces/infra/variables

variable "HCLOUD_TOKEN" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.HCLOUD_TOKEN) == 64
    error_message = "Please provide a valid Hetzner Cloud API token"
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

variable "SSHD_HOST_KEY_ALGORITHMS" {
  description = "SSHd public key algorithms accepted for an SSH server to authenticate itself to an SSH client"
  type        = list(string)

  validation {
    condition     = length(var.SSHD_HOST_KEY_ALGORITHMS) > 0
    error_message = "Please provide at least one SSHd host key algorithm"
  }
}

variable "SSHD_KEX_ALGORITHMS" {
  description = "SSHd key exchange methods that are used to generate per-connection keys"
  type        = list(string)

  validation {
    condition     = length(var.SSHD_KEX_ALGORITHMS) > 0
    error_message = "Please provide at least one SSHd key exchange algorithm"
  }
}

variable "SSHD_CIPHERS" {
  description = "SSHd ciphers to encrypt the connection"
  type        = list(string)

  validation {
    condition     = length(var.SSHD_CIPHERS) > 0
    error_message = "Please provide at least one SSHd cipher"
  }
}

variable "SSHD_MACS" {
  description = "SSHd message authentication codes used to detect traffic modification"
  type        = list(string)

  validation {
    condition     = length(var.SSHD_MACS) > 0
    error_message = "Please provide at least one SSHd MAC"
  }
}

variable "HTTP_PROXY_PORT" {
  description = "HTTP proxy port"
  type        = number
  sensitive   = true

  validation {
    condition     = var.HTTP_PROXY_PORT > 0 && var.HTTP_PROXY_PORT < 65536
    error_message = "Please provide a valid HTTP proxy port"
  }
}

variable "SSH_K3S_CLUSTER_KEY" {
  description = "SSH key for accessing the master node from worker nodes"
  type        = string
  sensitive   = true

  validation {
    condition     = can(var.SSH_K3S_CLUSTER_KEY)
    error_message = "Please provide a valid SSH key"
  }
}

variable "SSH_K3S_CLUSTER_KEY_PUB" {
  description = "The public part of the SSH key for accessing the master node from worker nodes"
  type        = string

  validation {
    condition     = can(var.SSH_K3S_CLUSTER_KEY_PUB)
    error_message = "Please provide a valid SSH public key"
  }
}

variable "SSH_K3S_CLUSTER_USER" {
  description = "Username to use for accessing the master node from worker nodes"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.SSH_K3S_CLUSTER_USER) > 0
    error_message = "Please provide a valid SSH user"
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
