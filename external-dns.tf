# Kubernetes Namespace (ExternalDNS)
resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

# Secret containing Cloudflare API Token
resource "kubernetes_secret_v1" "cloudflare_api_token" {
  depends_on = [
    kubernetes_namespace_v1.cert_manager,
    kubernetes_namespace_v1.external_dns
  ]

  # Deploy to each Namespace
  for_each = toset(["cert-manager", "external-dns"])

  metadata {
    name      = "cloudflare-api-token"
    namespace = each.value
  }

  immutable = true
  type      = "Opaque"

  data = {
    api-token = var.cloudflare_api_token
  }
}

# Helm chart (ExternalDNS)
resource "helm_release" "external_dns" {
  depends_on = [
    kubernetes_secret_v1.cloudflare_api_token["external-dns"],
    helm_release.cilium
  ]

  chart      = "external-dns"
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "external-dns"

  upgrade_install = true
  version         = var.external_dns_version

  values = [
    yamlencode({
      provider = {
        # Use Cloudflare as the DNS provider
        name = "cloudflare"
      }

      env = [
        # Cloudflare API token
        {
          name = "CF_API_TOKEN"
          valueFrom = {
            secretKeyRef = {
              name = "cloudflare-api-token"
              key  = "api-token"
            }
          }
        }
      ]

      # Limit target zone to personal domain
      domainFilters = [
        data.cloudflare_zone.default.name
      ]

      # Only watch resources with the following label
      labelFilter = "external-dns==enabled"

      # Query Gateway API resources for endpoints
      sources = [
        "service",
        "ingress",
        "gateway-httproute",
        "gateway-grpcroute"
      ]
    })
  ]

  timeout = 600
}
