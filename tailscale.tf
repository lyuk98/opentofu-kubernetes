# Kubernetes Namespace (Tailscale)
resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
    labels = {
      # Enforce "privileged" Pod Security Standards policy
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

# Helm chart (Tailscale Kubernetes Operator)
resource "helm_release" "tailscale_operator" {
  depends_on = [
    kubernetes_namespace_v1.tailscale,
    helm_release.cilium
  ]

  chart      = "tailscale-operator"
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "tailscale"

  upgrade_install = true
  version         = var.tailscale_operator_version

  set = [
    {
      name  = "apiServerProxyConfig.mode"
      value = "true"
    }
  ]
  set_sensitive = [
    {
      name  = "oauth.clientId"
      value = tailscale_oauth_client.kubernetes_operator.id
    },
    {
      name  = "oauth.clientSecret"
      value = tailscale_oauth_client.kubernetes_operator.key
    }
  ]

  timeout = 600
}

# Helm chart (Argo CD application - Tailscale Kubernetes Operator)
resource "helm_release" "argocd_tailscale" {
  depends_on = [
    helm_release.argocd_cert_manager,
    helm_release.tailscale_operator,
    helm_release.external_dns
  ]

  chart      = "argocd-apps"
  name       = "argocd-application-tailscale"
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
        argocd-application-tailscale = {
          namespace  = "argocd"
          finalizers = ["resources-finalizer.argocd.argoproj.io"]
          project    = "argocd-project-kubernetes"

          # Tailscale Gateway configuration
          source = {
            path           = "tailscale"
            repoURL        = "https://github.com/lyuk98/argocd-kubernetes"
            targetRevision = "main"
            kustomize = {
              patches = [
                {
                  target = {
                    kind = "Gateway"
                    name = "tailscale"
                  }
                  patch = yamlencode([
                    {
                      op    = "replace"
                      path  = "/spec/listeners/0/hostname"
                      value = "*.${local.tailnet_domain}"
                    }
                  ])
                }
              ]
            }
          }
          destination = {
            name      = "in-cluster"
            namespace = "tailscale"
          }

          syncPolicy = local.application_sync_policy
        }
      }
    })
  ]
}

# OAuth client for Tailscale Kubernetes Operator
resource "tailscale_oauth_client" "kubernetes_operator" {
  scopes      = ["devices:core", "auth_keys", "services"]
  description = "k8s-operator"
  tags        = ["tag:k8s-operator"]
}
