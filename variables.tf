variable "state_passphrase" {
  type        = string
  description = "Passphrase for state and plan encryption"
  sensitive   = true
  nullable    = false
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID"
  sensitive   = true
  nullable    = false
}

variable "talos_version" {
  type        = string
  description = "Version of Talos Linux"
  default     = "v1.12.4"
  nullable    = false
}

variable "kubernetes_version" {
  type        = string
  description = "Version of Kubernetes to use with Talos Linux"
  default     = "v1.35.1"
  nullable    = false
}

variable "node_xps13" {
  type        = string
  description = "Node address (XPS 13)"
  default     = "xps13"
}
