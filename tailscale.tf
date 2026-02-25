provider "tailscale" {
  scopes = ["devices:core", "auth_keys", "oauth_keys", "services"]
}

# OAuth client for Tailscale Kubernetes Operator
resource "tailscale_oauth_client" "kubernetes_operator" {
  scopes      = ["devices:core", "auth_keys", "services"]
  description = "k8s-operator"
  tags        = ["tag:k8s-operator"]
}

# Tailnet device information (Kubernetes Operator)
data "tailscale_device" "kubernetes_operator" {
  depends_on = [helm_release.tailscale_operator]
  hostname   = "tailscale-operator"
  wait_for   = "5m"
}

# OAuth client for node (XPS 13)
resource "tailscale_oauth_client" "xps13" {
  scopes      = ["auth_keys"]
  description = local.hostnames.control_plane.xps13
  tags        = ["tag:k8s-control-plane", "tag:k8s-worker"]
}

# Tailnet device information (XPS 13)
data "tailscale_device" "xps13" {
  depends_on = [talos_machine_configuration_apply.xps13]
  hostname   = local.hostnames.control_plane.xps13
  wait_for   = "10m"
}
