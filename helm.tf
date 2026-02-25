provider "helm" {
  kubernetes = {
    host = local.cluster_endpoint

    client_certificate     = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.ca_certificate)
  }
}

# Helm chart for Cilium
resource "helm_release" "cilium" {
  depends_on = [talos_cluster_kubeconfig.kubernetes]

  chart      = "cilium"
  name       = "cilium"
  repository = "https://helm.cilium.io/"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "kube-system"

  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = false
    },
    {
      name = "securityContext.capabilities.ciliumAgent"
      value = "{${
        join(
          ",",
          [
            "CHOWN",
            "KILL",
            "NET_ADMIN",
            "NET_RAW",
            "IPC_LOCK",
            "SYS_ADMIN",
            "SYS_RESOURCE",
            "DAC_OVERRIDE",
            "FOWNER",
            "SETGID",
            "SETUID"
          ]
        )
      }}"
    },
    {
      name = "securityContext.capabilities.cleanCiliumState"
      value = "{${
        join(
          ",",
          [
            "NET_ADMIN",
            "SYS_ADMIN",
            "SYS_RESOURCE"
          ]
        )
      }}"
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = false
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    }
  ]

  timeout = 600
}

# Helm chart for Tailscale Kubernetes Operator
resource "helm_release" "tailscale_operator" {
  depends_on = [helm_release.cilium]

  chart      = "tailscale-operator"
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"

  atomic           = true
  cleanup_on_fail  = true
  create_namespace = true
  namespace        = "tailscale"

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
