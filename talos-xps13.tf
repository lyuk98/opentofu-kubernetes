# Apply machine configuration (XPS 13)
resource "talos_machine_configuration_apply" "xps13" {
  client_configuration        = talos_machine_secrets.kubernetes.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = var.node_xps13

  config_patches = [for patch in values(local.talos_patches_xps13) : yamlencode(patch)]
}

# Bootstrap node (XPS 13)
resource "talos_machine_bootstrap" "xps13" {
  depends_on = [data.tailscale_device.xps13]
  lifecycle {
    replace_triggered_by = [talos_machine_configuration_apply.xps13.id]
  }

  client_configuration = talos_machine_secrets.kubernetes.client_configuration
  node                 = local.hostnames.control_plane.xps13
}

locals {
  # Commonly used volume encryption configuration for this host
  talos_encryption_xps13 = {
    provider = "luks2"
    keys = [
      # Encryption with static passphrase
      {
        slot = 0
        static = {
          passphrase = random_password.talos_encryption_passphrase_xps13.result
        }

        # Lock decryption key to the STATE partition
        lockToState = true
      }
    ]
  }

  # Patches specific to this node
  talos_patches_xps13 = {
    # Set hostname
    hostname = {
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      auto       = "off"
      hostname   = local.hostnames.control_plane.xps13
    }

    # Installation specification
    install = {
      machine = {
        install = {
          disk  = "/dev/nvme0n1"
          image = data.talos_image_factory_urls.xps13.urls.installer_secureboot
          wipe  = true
        }
      }
    }

    # Tailscale extension configuration
    tailscale = {
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"

      # Add environment variables
      environment = [
        "TS_AUTHKEY=${tailscale_oauth_client.xps13.key}",
        "TS_HOSTNAME=${local.hostnames.control_plane.xps13}",
        "TS_ROUTES=${
          join(
            ",",
            concat(
              local.talos_patches_controlplane.subnets.cluster.network.podSubnets,
              local.talos_patches_controlplane.subnets.cluster.network.podSubnets
            )
          )
        }",
        "TS_EXTRA_ARGS=--advertise-tags=${join(",", tailscale_oauth_client.xps13.tags)}"
      ]
    }

    # Volume configuration - ephemeral data storage
    volume_ephemeral = {
      apiVersion = "v1alpha1"
      kind       = "VolumeConfig"
      name       = "EPHEMERAL"

      provisioning = {
        diskSelector = {
          match = "disk.transport == \"nvme\""
        }
        grow    = true
        minSize = "16GiB"
        maxSize = "220GiB"
      }

      encryption = local.talos_encryption_xps13
    }

    # Volume configuration - system state storage
    volume_state = {
      apiVersion = "v1alpha1"
      kind       = "VolumeConfig"
      name       = "STATE"

      encryption = {
        provider = "luks2"
        keys = [
          # Automatic decryption with TPM
          {
            slot = 0
            tpm  = {}
          },
          # Encryption with key derived from the node UUID
          {
            slot   = 1
            nodeID = {}
          }
        ]
      }
    }

    # Volume configuration - swap volume
    volume_swap = {
      apiVersion = "v1alpha1"
      kind       = "SwapVolumeConfig"
      name       = "swap"

      provisioning = {
        diskSelector = {
          match = "disk.transport == \"nvme\""
        }
        minSize = "4GiB"
        maxSize = "16GiB"
      }
    }
  }
}

# Random password for disk encryption
resource "random_password" "talos_encryption_passphrase_xps13" {
  length = 64
}

# Image Factory schematic
resource "talos_image_factory_schematic" "xps13" {
  schematic = yamlencode({
    customization = {
      extraKernelArgs = [
        # Disable display output
        "video=eDP-1:d"
      ]

      systemExtensions = {
        officialExtensions = [
          "siderolabs/i915",
          "siderolabs/intel-ucode",
          "siderolabs/tailscale"
        ]
      }
      bootloader = "sd-boot"
    }
  })
}

# Host-specific Talos Linux image
data "talos_image_factory_urls" "xps13" {
  schematic_id  = talos_image_factory_schematic.xps13.id
  talos_version = var.talos_version
  architecture  = "amd64"
  platform      = "metal"
}
