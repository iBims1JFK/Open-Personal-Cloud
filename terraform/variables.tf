variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "List of SSH public keys to add to the server"
  type        = list(string)
  default     = []
}
