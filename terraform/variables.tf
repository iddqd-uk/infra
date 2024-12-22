# this file defines all the input variable declarations
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

  validation {
    condition     = var.HTTP_PROXY_PORT > 0 && var.HTTP_PROXY_PORT < 65536
    error_message = "Please provide a valid HTTP proxy port"
  }
}

variable "SSH_DEPLOY_KEY" { # unused, but kept for reference
  description = "The private part of the deployment SSH key"
  type        = string
  sensitive   = true
}

variable "SSH_DEPLOY_USER" {
  description = "The user to deploy applications using SSH + Docker"
  type        = string

  validation {
    condition     = length(var.SSH_DEPLOY_USER) > 0
    error_message = "Please provide a valid SSH deploy user"
  }
}

variable "SSH_DEPLOY_KEY_PUB" {
  description = "The public part of the deployment SSH key"
  type        = string

  validation {
    condition     = can(var.SSH_DEPLOY_KEY_PUB)
    error_message = "Please provide a valid SSH public key"
  }
}
