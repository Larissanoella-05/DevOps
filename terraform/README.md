# AgriPulse — Terraform Infrastructure

Infrastructure as Code for the AgriPulse app on Azure. Terraform provisions a
three-tier network, a public **bastion** host, a **private** application VM, a
managed **PostgreSQL** database, and a private **container registry** the CD
pipeline pushes images to.

## Architecture

```
                 internet
                    │
                    ▼
        ┌───────────────────────┐   public subnet
        │  Bastion (public IP)  │   SSH from admin IPs, fronts web traffic
        └───────────┬───────────┘
                    │ SSH / proxy (in-VNet only)
                    ▼
        ┌───────────────────────┐   private subnet
        │  App VM (no public IP)│   runs the Docker container
        └───────────┬───────────┘
                    │ private DNS
                    ▼
        ┌───────────────────────┐   delegated subnet
        │  PostgreSQL (private) │   no public endpoint
        └───────────────────────┘

  Azure Container Registry ──▶ image source for the app VM / CD pipeline
```

The app VM has **no public IP**. Ansible (and admins) reach it only by hopping
through the bastion. The database has **no public endpoint** — it is reachable
only from inside the VNet.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — sign in
  with `az login`. Terraform reuses that session, so no cloud keys live in the repo.
- An SSH key pair. Generate one with `ssh-keygen -t ed25519` if you don't have it —
  the default `ssh_public_key_path` expects an ed25519 key. Teammates who need
  access add their public keys to `extra_ssh_public_keys`.
- A database password exported as an environment variable (never committed):
  ```bash
  export TF_VAR_db_admin_password='<a-strong-password>'      # bash
  $env:TF_VAR_db_admin_password = '<a-strong-password>'      # PowerShell
  ```

## Layout

```
terraform/
├── main.tf            # provider, backend, resource group, module composition
├── variables.tf       # input variables (no hardcoded values)
├── outputs.tf         # exposed IPs, endpoints and resource IDs
├── terraform.tfvars   # dev environment values (auto-loaded — this is the default)
├── environments/
│   ├── staging.tfvars # staging environment values
│   └── prod.tfvars    # prod environment values
└── modules/
    ├── network/       # VNet + public, private and delegated DB subnets
    ├── security/      # NSGs: bastion (public) and app (private) tiers
    ├── bastion/       # public jump host
    ├── compute/       # private application VM
    ├── database/      # managed PostgreSQL (private) + private DNS
    └── registry/      # Azure Container Registry
```

## Usage

```bash
cd terraform

az login                                          # once per session
export TF_VAR_db_admin_password='<a-strong-password>'

terraform init                                    # download providers + modules
terraform plan                                    # preview
terraform apply                                   # create the infrastructure
terraform destroy                                 # tear it all down when finished
```

Values are read from `terraform.tfvars` automatically — that's the **dev**
environment, and the one currently deployed.

## Environments

`dev`, `staging`, and `prod` share the same module code; only the values in
each environment's `.tfvars` file differ (VM/database sizing mainly — the
network layout and security posture stay identical on purpose, so staging is
a faithful rehearsal of prod, not a different shape).

Each environment needs its own [Terraform
workspace](https://developer.hashicorp.com/terraform/language/state/workspaces)
so their state stays separate even with the local backend used today —
without this, applying staging or prod would overwrite dev's state file.
`dev` uses the default workspace (nothing extra to do); staging and prod
need one extra command the first time:

```bash
# dev (default workspace, terraform.tfvars auto-loads)
terraform apply

# staging
terraform workspace select -or-create staging
terraform apply -var-file=environments/staging.tfvars

# prod
terraform workspace select -or-create prod
terraform apply -var-file=environments/prod.tfvars

# switch back to dev
terraform workspace select default
```

Always check `terraform workspace show` before running `apply` or `destroy`
— it's easy to forget which one you're on, and `destroy` doesn't ask twice.

## Resources created

| Resource | Purpose |
| --- | --- |
| `azurerm_resource_group` | Holds every resource below |
| `azurerm_virtual_network` + 3 `azurerm_subnet` | Public, private and delegated DB tiers |
| `azurerm_network_security_group` ×2 (+ associations) | Bastion and app-tier firewalls |
| `azurerm_public_ip` + `azurerm_network_interface` + `azurerm_linux_virtual_machine` (bastion) | Public jump host |
| `azurerm_network_interface` + `azurerm_linux_virtual_machine` (app) | Private application VM |
| `azurerm_postgresql_flexible_server` (+ private DNS zone & link) | Managed database, VNet-private |
| `azurerm_container_registry` | Private image registry |

## Key variables

| Variable | Description | Default |
| --- | --- | --- |
| `location` | Azure region | _required_ |
| `vm_size` / `bastion_vm_size` | App / bastion VM size | _required_ / `Standard_B2ts_v2` |
| `ssh_ingress_cidrs` | Admin IPs allowed to SSH the bastion (list) | _required_ |
| `app_ingress_cidr` | Source allowed to reach the app port | `*` |
| `db_admin_username` | PostgreSQL admin login | `psqladmin` |
| `db_admin_password` | PostgreSQL admin password (via `TF_VAR_`) | _required_ |
| `acr_name` | Registry base name (random suffix appended) | _required_ |

Full list with defaults is in `variables.tf`.

## Outputs

| Output | Used by |
| --- | --- |
| `bastion_public_ip` | Ansible inventory (public host) + public app URL |
| `app_private_ip` | Ansible inventory (private target host) |
| `acr_login_server` | CD pipeline — where images are pushed/pulled |
| `acr_admin_username` / `acr_admin_password` | CD pipeline `docker login` (password is sensitive) |
| `database_fqdn` | App DB connection string |

```bash
terraform output -raw bastion_public_ip
terraform output -raw app_private_ip
```

## Remote state

State is local by default. To store it remotely, create a storage account and
container once, then uncomment the `backend "azurerm"` block in `main.tf` and
re-run `terraform init`:

```bash
az group create --name agripulse-tfstate-rg --location centralindia
az storage account create --name agripulsetfstate \
  --resource-group agripulse-tfstate-rg --sku Standard_LRS
az storage container create --name tfstate --account-name agripulsetfstate
```

## Notes

- `terraform.tfvars` is committed on purpose — it holds no secrets. The DB
  password comes from `TF_VAR_db_admin_password`; state files and the SSH private
  key are gitignored and never leave your machine.
- The registry and database names get a short random suffix so they stay globally
  unique across re-deploys.
- The managed PostgreSQL server is provisioned as required infrastructure. The app
  currently persists to SQLite, so wiring it to PostgreSQL is documented as future
  work rather than an active dependency.
