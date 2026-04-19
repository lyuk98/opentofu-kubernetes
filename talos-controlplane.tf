# Machine configuration for control plane nodes
data "talos_machine_configuration" "controlplane" {
  cluster_endpoint = local.cluster_endpoint
  cluster_name     = local.cluster_name
  machine_secrets  = talos_machine_secrets.kubernetes.machine_secrets
  machine_type     = "controlplane"

  kubernetes_version = var.kubernetes_version
  talos_version      = var.talos_version

  config_patches = concat(
    [for patch in values(local.talos_patches_common) : yamlencode(patch)],
    [for patch in values(local.talos_patches_controlplane) : yamlencode(patch)]
  )
}

locals {
  # Patches for control plane nodes
  talos_patches_controlplane = {
    # Disable default CNI (Flannel) in favour of Cilium
    disable_cni = {
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
      }
    }

    # Disable kube-proxy
    disable_proxy = {
      cluster = {
        proxy = {
          disabled = true
        }
      }
    }

    # Allow running workload on control plane nodes
    run_workload = {
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    }

    # Define cluster subnets
    subnets = {
      cluster = {
        network = {
          podSubnets     = ["10.244.0.0/16", "fd00:10:244::/56"]
          serviceSubnets = ["10.96.0.0/12", "fd00:10:96::/112"]
        }
      }
    }
  }
}
