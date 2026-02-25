terraform {
  # State backend
  backend "s3" {
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    region                      = "us-west-002"

    key = "opentofu-state-kubernetes"
  }

  # State encryption
  encryption {
    # Key provider
    key_provider "pbkdf2" "key_provider_pbkdf2" {
      passphrase = var.state_passphrase
    }

    # Encryption method
    method "aes_gcm" "method_aes_gcm" {
      keys = key_provider.pbkdf2.key_provider_pbkdf2
    }

    state {
      # State data encryption method
      method = method.aes_gcm.method_aes_gcm

      # Enforce state encryption
      enforced = true
    }

    plan {
      # Plan data encryption method
      method = method.aes_gcm.method_aes_gcm

      # Enforce plan encryption
      enforced = true
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.17"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.8"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.27"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

# Local resource management
provider "local" {}

# Random value generation
provider "random" {}

# Management of time-based resources
provider "time" {}
