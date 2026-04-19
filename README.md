# OpenTofu configurations

This repository contains OpenTofu configuration for my personal Kubernetes cluster.

## Providers used

```mermaid
flowchart RL
  %% Resource/data source declaration

  %% argocd.tf
  kubernetes_namespace_v1.argocd
  helm_release.argocd
  helm_release.argocd_project
  helm_release.argocd_application

  %% cert-manager.tf
  kubernetes_namespace_v1.cert_manager
  helm_release.cert_manager
  helm_release.argocd_cert_manager

  %% cilium.tf
  data.kustomization_build.gateway_api([data.kustomization_build.gateway_api])
  kustomization_resource.gateway_api_p0
  kustomization_resource.gateway_api_p1
  kustomization_resource.gateway_api_p2
  helm_release.cilium

  %% cloudflare.tf
  data.cloudflare_zone.default([data.cloudflare_zone.default])
  time_sleep.dns_ready
  terraform_data.dns_ready
  cloudflare_dns_record.xps13_a
  cloudflare_dns_record.xps13_aaaa

  %% external-dns.tf
  kubernetes_namespace_v1.external_dns
  kubernetes_secret_v1.cloudflare_api_token
  helm_release.external_dns

  %% tailscale.tf
  kubernetes_namespace_v1.tailscale
  helm_release.tailscale_operator
  helm_release.argocd_tailscale
  tailscale_oauth_client.kubernetes_operator

  %% talos-controlplane.tf
  data.talos_machine_configuration.controlplane([data.talos_machine_configuration.controlplane])

  %% talos-xps13.tf
  talos_machine_configuration_apply.xps13
  talos_machine_bootstrap.xps13
  random_password.talos_encryption_passphrase_xps13
  talos_image_factory_schematic.xps13
  data.talos_image_factory_urls.xps13([data.talos_image_factory_urls.xps13])
  tailscale_oauth_client.xps13
  data.tailscale_device.xps13([data.tailscale_device.xps13])

  %% talos.tf
  talos_machine_secrets.kubernetes
  data.talos_client_configuration.kubernetes([data.talos_client_configuration.kubernetes])
  talos_cluster_kubeconfig.kubernetes
  local_sensitive_file.talosconfig
  local_sensitive_file.kubeconfig

  %% Relation declaration

  %% argocd.tf
  helm_release.argocd-- depends_on -->kubernetes_namespace_v1.argocd
  helm_release.argocd-- depends_on -->helm_release.cilium
  helm_release.argocd-- name -->data.cloudflare_zone.default
  helm_release.argocd_project-- depends_on -->kubernetes_namespace_v1.cert_manager
  helm_release.argocd_project-- depends_on -->kubernetes_namespace_v1.tailscale
  helm_release.argocd_project-- depends_on -->helm_release.argocd
  helm_release.argocd_application-- depends_on -->helm_release.argocd_tailscale
  helm_release.argocd_application-- name -->data.cloudflare_zone.default

  %% cert-manager.tf
  helm_release.cert_manager-- depends_on -->kubernetes_namespace_v1.cert_manager
  helm_release.cert_manager-- depends_on -->helm_release.cilium
  helm_release.argocd_cert_manager-- depends_on -->helm_release.argocd_project
  helm_release.argocd_cert_manager-- depends_on -->kubernetes_secret_v1.cloudflare_api_token

  %% cilium.tf
  kustomization_resource.gateway_api_p0-- ids_prio -->data.kustomization_build.gateway_api
  kustomization_resource.gateway_api_p1-- depends_on -->kustomization_resource.gateway_api_p0
  kustomization_resource.gateway_api_p1-- ids_prio -->data.kustomization_build.gateway_api
  kustomization_resource.gateway_api_p2-- depends_on -->kustomization_resource.gateway_api_p1
  kustomization_resource.gateway_api_p2-- ids_prio -->data.kustomization_build.gateway_api
  helm_release.cilium-- depends_on -->kustomization_resource.gateway_api_p2

  %% cloudflare.tf
  time_sleep.dns_ready-- content -->cloudflare_dns_record.xps13_a
  time_sleep.dns_ready-- content -->cloudflare_dns_record.xps13_aaaa
  terraform_data.dns_ready-- triggers_replace -->time_sleep.dns_ready
  terraform_data.dns_ready-- name -->data.cloudflare_zone.default
  terraform_data.dns_ready-- triggers -->time_sleep.dns_ready
  cloudflare_dns_record.xps13_a-- addresses -->data.tailscale_device.xps13
  cloudflare_dns_record.xps13_aaaa-- addresses -->data.tailscale_device.xps13

  %% external-dns.tf
  kubernetes_secret_v1.cloudflare_api_token-- depends_on -->kubernetes_namespace_v1.cert_manager
  kubernetes_secret_v1.cloudflare_api_token-- depends_on -->kubernetes_namespace_v1.external_dns
  helm_release.external_dns-- depends_on -->kubernetes_secret_v1.cloudflare_api_token
  helm_release.external_dns-- depends_on -->helm_release.cilium
  helm_release.external_dns-- name -->data.cloudflare_zone.default

  %% tailscale.tf
  helm_release.tailscale_operator-- depends_on -->kubernetes_namespace_v1.tailscale
  helm_release.tailscale_operator-- depends_on -->helm_release.cilium
  helm_release.tailscale_operator-- id -->tailscale_oauth_client.kubernetes_operator
  helm_release.tailscale_operator-- key -->tailscale_oauth_client.kubernetes_operator
  helm_release.argocd_tailscale-- depends_on -->helm_release.argocd_cert_manager
  helm_release.argocd_tailscale-- depends_on -->helm_release.tailscale_operator
  helm_release.argocd_tailscale-- depends_on -->helm_release.external_dns
  helm_release.argocd_tailscale-- name -->data.cloudflare_zone.default

  %% talos-controlplane.tf
  data.talos_machine_configuration.controlplane-- name -->data.cloudflare_zone.default
  data.talos_machine_configuration.controlplane-- machine_secrets -->talos_machine_secrets.kubernetes

  %% talos-xps13.tf
  talos_machine_configuration_apply.xps13-- client_configuration -->talos_machine_secrets.kubernetes
  talos_machine_configuration_apply.xps13-- machine_configuration -->data.talos_machine_configuration.controlplane
  talos_machine_configuration_apply.xps13-- urls -->data.talos_image_factory_urls.xps13
  talos_machine_configuration_apply.xps13-- key -->tailscale_oauth_client.xps13
  talos_machine_configuration_apply.xps13-- tags -->tailscale_oauth_client.xps13
  talos_machine_configuration_apply.xps13-- result -->random_password.talos_encryption_passphrase_xps13
  talos_machine_bootstrap.xps13-- depends_on -->data.tailscale_device.xps13
  talos_machine_bootstrap.xps13-- replace_triggered_by -->talos_machine_configuration_apply.xps13
  talos_machine_bootstrap.xps13-- client_configuration -->talos_machine_secrets.kubernetes
  data.talos_image_factory_urls.xps13-- id -->talos_image_factory_schematic.xps13
  tailscale_device.xps13-- depends_on -->talos_machine_configuration_apply.xps13

  %% talos.tf
  data.talos_client_configuration.kubernetes-- client_configuration -->talos_machine_secrets.kubernetes
  data.talos_client_configuration.kubernetes-- content -->cloudflare_dns_record.xps13_a
  talos_cluster_kubeconfig.kubernetes-- depends_on -->terraform_data.dns_ready
  talos_cluster_kubeconfig.kubernetes-- replace_triggered_by -->talos_machine_secrets.kubernetes
  talos_cluster_kubeconfig.kubernetes-- client_configuration -->talos_machine_secrets.kubernetes
  talos_cluster_kubeconfig.kubernetes-- content -->cloudflare_dns_record.xps13_a
  local_sensitive_file.talosconfig-- talos_config -->data.talos_client_configuration.kubernetes
  local_sensitive_file.kubeconfig-- kubeconfig_raw -->talos_cluster_kubeconfig.kubernetes
```

### Talos Linux

- Machine secrets for the cluster (`talos_machine_secrets`)
- Machine configuration for nodes (`talos_machine_configuration`)
- Schematic from [Image Factory](https://factory.talos.dev/) (`talos_image_factory_schematic`)
- Generated password for disk encryption (`random_password`)
- Installation and bootstrapping of nodes (`talos_machine_configuration_apply` and `talos_machine_bootstrap`)
- `kubeconfig` generated by Talos Linux (`talos_cluster_kubeconfig`)

### Tailscale

- Trust credentials for nodes and [Tailscale Kubernetes Operator](https://tailscale.com/docs/features/kubernetes-operator) (`tailscale_oauth_client`)

### Cloudflare

- `A` and `AAAA` records for control plane nodes (`cloudflare_dns_record`)
- Delayed creation of resource to wait for DNS propagation (`time_sleep`)
- Execution of [Python script](./scripts/check_dns.py) to check for DNS propagation (`terraform_data` with `local-exec`)

### Kubernetes

- Namespace declaration (`kubernetes_namespace_v1`)
- Secret provisioning (`kubernetes_secret_v1`)

### Kustomize

- Kustomization resource application (`kustomization_resource`)

### Helm

- Helm charts for: (`helm_release`)
  - [Cilium](https://cilium.io/)
  - [Tailscale Kubernetes Operator](https://tailscale.com/docs/features/kubernetes-operator)
  - [cert-manager](https://cert-manager.io/ "cert-manager")
  - [ExternalDNS](https://kubernetes-sigs.github.io/external-dns/ "external-dns")
  - [Argo CD](https://argoproj.github.io/cd/ "Argo CD | Argo") and its applications

## Applying the configuration

OpenTofu is required due to the usage of [state and plan encryption](https://opentofu.org/docs/language/state/encryption/); using Terraform without it may work, but it has not been tested. Python 3 is also required for local script execution.

If the system uses [Nix](https://nixos.org/), running the following command, at the root directory of the cloned project, starts an interactive shell with required packages:

```sh
nix-shell --pure
```

### Environment variables

This configuration assumes that some environment variables are set prior to the following steps.

#### `s3` backend

Backblaze B2 is used for storing the state.

- `AWS_SECRET_ACCESS_KEY`: the application key to access the bucket with. The following capabilities are required: `deleteFiles`, `listBuckets`, `listFiles`, `readFiles`, and `writeFiles`
- `AWS_ACCESS_KEY_ID`: the ID of the abovementioned application key
- `AWS_ENDPOINT_URL_S3`: S3 API endpoint, such as `https://s3.us-west-002.backblazeb2.com`

#### `tailscale` provider

- `TAILSCALE_OAUTH_CLIENT_SECRET`: the OAuth client used for deployment; this setup assumes that the scopes `devices:core`, `auth_keys`, `oauth_keys`, and `services` are assigned with tags either:
  - `tag:k8s-operator` and `tag:k8s-control-plane` themselves, or
  - one that owns the above
- `TAILSCALE_OAUTH_CLIENT_ID`: the ID of the abovementioned OAuth client

### Input variables

Accepted input variables are defined at [`variables.tf`](./variables.tf). The following do not have default values and thus need to be manually set:

- `state_passphrase`: the passphrase used for encrypting and decrypting state and plan data
- `cloudflare_zone_id`: Cloudflare zone ID
- `cloudflare_api_token`: Cloudflare API token with permissions to edit zone DNS
- `acme_email`: Email for ACME ClusterIssuer configuration

### Backend configuration

During initialisation, the name of the bucket for storing the state needs to be provided. It can be done interactively, or by manually providing the configuration.

```sh
# Initialise backend interactively
tofu init

# Initialise backend with configuration
tofu init -backend-config="bucket=<bucket-name>"
```

### `plan` and `apply`

When the backend is ready, run the following to apply the configuration:

```sh
tofu plan -out=tfplan
tofu apply tfplan
```
