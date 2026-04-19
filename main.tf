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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9.7"
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

# Cloudflare resource management
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Helm package manager
provider "helm" {
  kubernetes = {
    host = local.cluster_endpoint

    client_certificate     = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.ca_certificate)
  }
}

# Kubernetes resource management
provider "kubernetes" {
  host = local.cluster_endpoint

  client_certificate     = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.kubernetes.kubernetes_client_configuration.ca_certificate)
}

# Kustomization provider
provider "kustomization" {
  kubeconfig_raw = talos_cluster_kubeconfig.kubernetes.kubeconfig_raw
}

# Local resource management
provider "local" {}

# Random value generation
provider "random" {}

# Tailscale provider
provider "tailscale" {
  scopes = ["devices:core", "auth_keys", "oauth_keys", "services"]
}

# Talos Linux
provider "talos" {}

# Management of time-based resources
provider "time" {}
