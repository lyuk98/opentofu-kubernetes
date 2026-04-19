locals {
  # Patches for cert-manager Kustomization
  cert_manager_patch = yamlencode([
    {
      op    = "replace"
      path  = "/spec/acme/email"
      value = var.acme_email
    }
  ])
}

# Kubernetes Namespace (cert-manager)
resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# Helm chart (cert-manager)
resource "helm_release" "cert_manager" {
  depends_on = [
    kubernetes_namespace_v1.cert_manager,
    helm_release.cilium
  ]

  chart      = "cert-manager"
  name       = "cert-manager"
  repository = "https://charts.jetstack.io/"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "cert-manager"

  upgrade_install = true
  version         = var.cert_manager_version

  values = [
    yamlencode({
      crds = {
        enabled = true
      }
      config = {
        enableGatewayAPI = true
      }
    })
  ]
}

# Helm chart (Argo CD Application - cert-manager)
resource "helm_release" "argocd_cert_manager" {
  depends_on = [
    helm_release.argocd_project,
    kubernetes_secret_v1.cloudflare_api_token
  ]

  chart      = "argocd-apps"
  name       = "argocd-application-cert-manager"
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
        argocd-application-cert-manager = {
          namespace  = "argocd"
          finalizers = ["resources-finalizer.argocd.argoproj.io"]
          project    = "argocd-project-kubernetes"

          # ClusterIssuer configuration
          source = {
            path           = "cert-manager"
            repoURL        = "https://github.com/lyuk98/argocd-kubernetes"
            targetRevision = "main"
            kustomize = {
              patches = [
                {
                  target = {
                    kind = "ClusterIssuer"
                    name = "letsencrypt-staging"
                  }
                  patch = local.cert_manager_patch
                },
                {
                  target = {
                    kind = "ClusterIssuer"
                    name = "letsencrypt"
                  }
                  patch = local.cert_manager_patch
                }
              ]
            }
          }
          destination = {
            name      = "in-cluster"
            namespace = "cert-manager"
          }

          syncPolicy = local.application_sync_policy
        }
      }
    })
  ]
}
