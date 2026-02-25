locals {
  # Patches for all nodes in the cluster
  talos_patches_common = {
    # Enable IP forwarding
    ip_forwarding = {
      machine = {
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
      }
    }

    # Allow Kubernetes workloads to use swap memory
    kubelet_swap = {
      machine = {
        kubelet = {
          extraConfig = {
            memorySwap = {
              swapBehavior = "LimitedSwap"
            }
          }
        }
      }
    }

    # KubeSpan configuration
    kubeswap = {
      machine = {
        network = {
          kubespan = {
            # Enable KubeSpan
            enabled = true
          }
        }
      }
      cluster = {
        discovery = {
          enabled = true
          # Registries used for cluster member discovery
          registries = {
            # Kubernetes registry is problematic with KubeSpan
            # if the control plane endpoint is routeable itself via KubeSpan
            kubernetes = {
              disabled = true
            }
            service = {}
          }
        }
      }
    }

    # DNS resolver configuration
    resolver = {
      apiVersion = "v1alpha1"
      kind       = "ResolverConfig"

      # List of nameservers for domain name resolution
      nameservers = [
        { address = "100.100.100.100" },
        { address = "1.1.1.1" },
        { address = "8.8.8.8" },
        { address = "9.9.9.9" },
        { address = "1.0.0.1" },
        { address = "8.8.4.4" },
        { address = "149.112.112.112" },
        { address = "2606:4700:4700::1111" },
        { address = "2001:4860:4860::8888" },
        { address = "2620:fe::fe" },
        { address = "2606:4700:4700::1001" },
        { address = "2001:4860:4860::8844" },
        { address = "2620:fe::9" }
      ]
    }

    # Enable zswap
    zswap = {
      apiVersion = "v1alpha1"
      kind       = "ZswapConfig"

      # Use up to 30% of memory for zswap
      maxPoolPercent = 30

      # Allow kernel to move pages from zswap to swap
      shrinkerEnabled = true
    }
  }
}
