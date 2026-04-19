# Kustomization - Gateway API CRDs
data "kustomization_build" "gateway_api" {
  path = "github.com/kubernetes-sigs/gateway-api/config/crd?ref=${urlencode(var.gateway_api_version)}"
}

# Gateway API CRDs - priority 0
resource "kustomization_resource" "gateway_api_p0" {
  for_each = data.kustomization_build.gateway_api.ids_prio[0]
  manifest = data.kustomization_build.gateway_api.manifests[each.value]
}
# Gateway API CRDs - priority 1
resource "kustomization_resource" "gateway_api_p1" {
  depends_on = [kustomization_resource.gateway_api_p0]
  for_each   = data.kustomization_build.gateway_api.ids_prio[1]
  manifest   = data.kustomization_build.gateway_api.manifests[each.value]
}
# Gateway API CRDs - priority 2
resource "kustomization_resource" "gateway_api_p2" {
  depends_on = [kustomization_resource.gateway_api_p1]
  for_each   = data.kustomization_build.gateway_api.ids_prio[2]
  manifest   = data.kustomization_build.gateway_api.manifests[each.value]
}

# Helm chart (Cilium)
resource "helm_release" "cilium" {
  depends_on = [kustomization_resource.gateway_api_p2]

  chart      = "cilium"
  name       = "cilium"
  repository = "https://helm.cilium.io/"

  atomic          = true
  cleanup_on_fail = true
  namespace       = "kube-system"

  upgrade_install = true
  version         = var.cilium_version

  set = [
    # Set Kubernetes host-scope IPAM mode
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    # Capabilities for cilium-agent
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
    # Capabilities for clean-cilium-state
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
    # Automatically mount cgroup2 filesystem
    {
      name  = "cgroup.autoMount.enabled"
      value = false
    },
    # Custom cgroup root
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    # Configure the kube-proxy replacement
    {
      name  = "kubeProxyReplacement"
      value = true
    },
    # Enable Cilium's Gateway API implementation
    {
      name  = "gatewayAPI.enabled"
      value = true
    },
    # Enable dedicated Envoy proxy DaemonSet
    {
      name  = "envoy.enabled"
      value = true
    },
    # Enable CiliumEnvoyConfig CRD
    {
      name  = "envoyConfig.enabled"
      value = true
    }
  ]

  timeout = 600
}
