variable "state_passphrase" {
  type        = string
  description = "Passphrase for state and plan encryption"
  sensitive   = true
  nullable    = false
}

variable "node_xps13" {
  type        = string
  description = "Node address (XPS 13)"
  default     = "xps13"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID"
  sensitive   = true
  nullable    = false
}

variable "cloudflare_api_token" {
  type        = string
  description = "API token for Cloudflare operations"
  sensitive   = true
  nullable    = false
}

variable "acme_email" {
  type        = string
  description = "Email for ACME ClusterIssuer configuration"
  sensitive   = true
  nullable    = false
}

variable "talos_version" {
  type        = string
  description = "Version of Talos Linux"
  default     = "v1.12.6"
  nullable    = false
}

variable "kubernetes_version" {
  type        = string
  description = "Version of Kubernetes to use with Talos Linux"
  default     = "v1.35.3"
  nullable    = false
}

variable "argocd_version" {
  type        = string
  description = "Version of the Helm chart for Argo CD"
  default     = "9.5.0"
  nullable    = false
}

variable "argocd_apps_version" {
  type        = string
  description = "Version of the argocd-apps Helm chart"
  default     = "2.0.4"
  nullable    = false
}

variable "cert_manager_version" {
  type        = string
  description = "Version of the Helm chart for cert-manager"
  default     = "1.20.2"
  nullable    = false
}

variable "cilium_version" {
  type        = string
  description = "Version of the Helm chart for Cilium"
  default     = "1.19.2"
  nullable    = false
}

variable "external_dns_version" {
  type        = string
  description = "Version of the Helm chart for ExternalDNS"
  default     = "1.20.0"
  nullable    = false
}

variable "gateway_api_version" {
  type        = string
  description = "Version of Gateway API CRDs"
  default     = "v1.4.1"
  nullable    = false
}

variable "tailscale_operator_version" {
  type        = string
  description = "Version of the Helm chart for Tailscale Operator"
  default     = "1.96.5"
  nullable    = false
}
