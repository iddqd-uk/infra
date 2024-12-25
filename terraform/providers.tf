# this file defines the required providers and their versions

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud" // https://registry.terraform.io/providers/hetznercloud/hcloud
      version = "~> 1.49"
    }
  }

  cloud {
    organization = "iddqd-uk"

    workspaces {
      name = "infra"
    }
  }

  required_version = ">= 1.10.0"
}

provider "hcloud" {
  token = var.HCLOUD_TOKEN
}
