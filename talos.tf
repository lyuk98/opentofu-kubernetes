# Generate machine secrets for the cluster
resource "talos_machine_secrets" "kubernetes" {}

# Generate client configuration for the Talos Linux cluster
data "talos_client_configuration" "kubernetes" {
  client_configuration = talos_machine_secrets.kubernetes.client_configuration
  cluster_name         = local.cluster_name
  endpoints            = local.node_addresses.ipv4

  nodes = distinct(
    concat(values(local.hostnames.control_plane), values(local.hostnames.worker))
  )
}

# Generate kubeconfig for the cluster
resource "talos_cluster_kubeconfig" "kubernetes" {
  depends_on = [terraform_data.dns_ready]
  lifecycle {
    replace_triggered_by = [talos_machine_secrets.kubernetes.client_configuration]
  }

  client_configuration = talos_machine_secrets.kubernetes.client_configuration
  node                 = local.node_addresses.ipv4[0]
}

# Write client configuration to file
resource "local_sensitive_file" "talosconfig" {
  filename = "${path.module}/talosconfig"
  content  = data.talos_client_configuration.kubernetes.talos_config
}

# Write kubeconfig to file
resource "local_sensitive_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = talos_cluster_kubeconfig.kubernetes.kubeconfig_raw
}

locals {
  # The cluster name
  cluster_name = "kubernetes"

  # The cluster endpoint
  cluster_endpoint = "https://${local.cluster_subdomain}.${data.cloudflare_zone.default.name}:6443"

  # Hostnames
  hostnames = {
    control_plane = {
      xps13 = "xps13"
    }
    worker = {
      xps13 = "xps13"
    }
  }
}
