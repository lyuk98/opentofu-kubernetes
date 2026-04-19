locals {
  # Argo CD domain
  argocd_subdomain = "argo-cd.${local.tailnet_subdomain}"
  argocd_domain    = "${local.argocd_subdomain}.${data.cloudflare_zone.default.name}"

  # Common sync policy for Argo CD Applications
  application_sync_policy = {
    automated = {
      selfHeal = true
    }
  }

  # Patches for Argo CD routes
  argocd_route_patch = yamlencode([
    {
      op    = "add"
      path  = "/spec/hostnames/0"
      value = local.argocd_domain
    }
  ])
}

# Kubernetes Namespace (Argo CD)
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Helm chart (Argo CD)
resource "helm_release" "argocd" {
  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.cilium
  ]

  chart      = "argo-cd"
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "argocd"

  upgrade_install = true
  version         = var.argocd_version

  values = [
    yamlencode({
      # Set domain for all components
      global = {
        domain = local.argocd_domain
      }
      configs = {
        params = {
          # Run API server with TLS disabled for SSL termination
          "server.insecure" = true
        }
      }
    })
  ]
}

# Helm chart (AppProject - Argo CD)
resource "helm_release" "argocd_project" {
  depends_on = [
    kubernetes_namespace_v1.cert_manager,
    kubernetes_namespace_v1.tailscale,
    helm_release.argocd
  ]

  chart      = "argocd-apps"
  name       = "argocd-project-kubernetes"
  repository = "https://argoproj.github.io/argo-helm"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "argocd"

  upgrade_install = true
  version         = var.argocd_apps_version

  values = [
    yamlencode({
      projects = {
        # AppProject containing applications necessary for proper cluster operation
        argocd-project-kubernetes = {
          namespace   = "argocd"
          description = "Project for cluster's operation"

          # Only allow repository for this project
          sourceRepos = [
            "https://github.com/lyuk98/argocd-kubernetes"
          ]

          destinations = [
            # Allow deployments to namespace "argocd"
            {
              namespace = "argocd"
              name      = "in-cluster"
            },
            # Allow deployments to namespace "cert-manager"
            {
              namespace = "cert-manager"
              name      = "in-cluster"
            },
            # Allow deployments to namespace "tailscale"
            {
              namespace = "tailscale"
              name      = "in-cluster"
            }
          ]

          # List of CustomResourceDefinitions to allow for bootstrapping
          clusterResourceWhitelist = [
            for kind in [
              "CiliumGatewayClassConfig",
              "ClusterIssuer",
              "Gateway",
              "GatewayClass",
              "GRPCRoute",
              "HTTPRoute"
              ] : {
              group = "*"
              kind  = kind
            }
          ]
        }
      }
    })
  ]
}

# Helm chart (Argo CD Application - Argo CD)
resource "helm_release" "argocd_application" {
  depends_on = [helm_release.argocd_tailscale]

  chart      = "argocd-apps"
  name       = "argocd-application"
  repository = "https://argoproj.github.io/argo-helm"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "argocd"

  upgrade_install = true
  version         = var.argocd_apps_version

  values = [
    yamlencode({
      applications = {
        # Argo CD configuration
        argocd-application = {
          namespace  = "argocd"
          finalizers = ["resources-finalizer.argocd.argoproj.io"]
          project    = "argocd-project-kubernetes"
          source = {
            path           = "argocd"
            repoURL        = "https://github.com/lyuk98/argocd-kubernetes"
            targetRevision = "main"
            kustomize = {
              # Add custom domain to Kustomization
              patches = [
                {
                  target = {
                    kind = "HTTPRoute"
                    name = "argocd-http-route"
                  }
                  patch = local.argocd_route_patch
                },
                {
                  target = {
                    kind = "GRPCRoute"
                    name = "argocd-grpc-route"
                  }
                  patch = local.argocd_route_patch
                }
              ]
            }
          }
          destination = {
            name      = "in-cluster"
            namespace = "argocd"
          }

          syncPolicy = local.application_sync_policy
        }
      }
    })
  ]
}
