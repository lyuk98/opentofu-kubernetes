provider "cloudflare" {}

# Cloudflare Zone information
data "cloudflare_zone" "default" {
  zone_id = var.cloudflare_zone_id
}

locals {
  # Subdomain of control plane nodes
  cluster_subdomain = "kubernetes.clusters.tailnet"

  # IP addresses of control plane nodes
  node_addresses = {
    ipv4 = [
      cloudflare_dns_record.xps13_a.content
    ]
    ipv6 = [
      cloudflare_dns_record.xps13_aaaa.content
    ]
  }
}

# Wait for DNS propagation
resource "time_sleep" "dns_ready" {
  create_duration = "210s"

  triggers = {
    ipv4 = jsonencode(local.node_addresses.ipv4)
    ipv6 = jsonencode(local.node_addresses.ipv6)
  }
}

# Check for DNS propagation
resource "terraform_data" "dns_ready" {
  triggers_replace = [
    time_sleep.dns_ready.triggers.ipv4,
    time_sleep.dns_ready.triggers.ipv6
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/check_dns.py"
    environment = {
      TEST_ADDRESS     = data.cloudflare_zone.default.name
      ADDRESS          = "${local.cluster_subdomain}.${data.cloudflare_zone.default.name}"
      DNS_RECORDS_A    = time_sleep.dns_ready.triggers.ipv4
      DNS_RECORDS_AAAA = time_sleep.dns_ready.triggers.ipv6
      INTERVAL         = "10"
      TIMEOUT          = "600"
    }
  }
}

# Round-robin DNS records for control plane nodes

# A record (XPS 13)
resource "cloudflare_dns_record" "xps13_a" {
  name    = local.cluster_subdomain
  ttl     = 1
  type    = "A"
  zone_id = data.cloudflare_zone.default.zone_id

  content = data.tailscale_device.xps13.addresses[0]
  proxied = false
}

# AAAA record (XPS 13)
resource "cloudflare_dns_record" "xps13_aaaa" {
  name    = local.cluster_subdomain
  ttl     = 1
  type    = "AAAA"
  zone_id = data.cloudflare_zone.default.zone_id

  content = data.tailscale_device.xps13.addresses[1]
  proxied = false
}
