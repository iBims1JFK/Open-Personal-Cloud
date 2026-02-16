terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_server" "edge_node" {
  name        = "edge-node"
  image       = "ubuntu-24.04"
  server_type = "cpx11"
  location    = "nbg1"
  
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = file("${path.module}/cloud-init.yaml")
}
