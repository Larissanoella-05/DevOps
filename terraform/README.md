# AgriPulse — Terraform Infrastructure

Infrastructure as Code for the AgriPulse app. Terraform provisions the network,
a compute VM to run the Docker container, and the security rules around it on Azure.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) — sign in
  with `az login`. Terraform reuses that session, so no cloud keys live in the repo.
- An SSH key pair. The **public** key path goes in `terraform.tfvars`
  (`ssh_public_key_path`); the matching private key is what Ansible uses later.
  Generate one with `ssh-keygen -t rsa -b 4096` if you don't have it.

## Layout

```
terraform/
├── main.tf            # provider, backend, resource group, module composition
├── variables.tf       # input variables (no hardcoded values)
├── outputs.tf         # exposed IPs and resource IDs
├── terraform.tfvars   # actual values for this deployment
└── modules/
    ├── network/       # virtual network + subnet
    ├── security/      # network security group: SSH (22) + app port, deny rest
    └── compute/       # public IP + network interface + Ubuntu VM
```

## Usage

```bash
cd terraform

# 1. Sign in to Azure (once per session)
az login

# 2. Download providers and initialise the working directory
terraform init

# 3. Preview the changes Terraform will make
terraform plan

# 4. Create the infrastructure
terraform apply

# 5. Tear everything down when you're done
terraform destroy
```

Values are read from `terraform.tfvars` automatically. Override any of them
inline, e.g. `terraform apply -var="environment=prod"`.

## Resources created

| Resource | Purpose |
| --- | --- |
| `azurerm_resource_group` | Container that holds every resource below |
| `azurerm_virtual_network` | Isolated virtual network |
| `azurerm_subnet` | Subnet the VM lives in |
| `azurerm_network_security_group` (+ subnet association) | Allow ports 22 and 3000, deny everything else |
| `azurerm_public_ip` | Static public IP for the VM |
| `azurerm_network_interface` | NIC connecting the VM to the subnet and public IP |
| `azurerm_linux_virtual_machine` | Ubuntu VM that runs the AgriPulse container |

## Variables

| Variable | Description | Default |
| --- | --- | --- |
| `project_name` | Prefix for resource names and tags | `agripulse` |
| `environment` | Deployment environment | `dev` |
| `location` | Azure region | _required_ |
| `vm_size` | VM size | _required_ |
| `app_port` | App container port | `3000` |
| `vnet_cidr` | Virtual network CIDR | `10.0.0.0/16` |
| `subnet_cidr` | Subnet CIDR | `10.0.1.0/24` |
| `ssh_ingress_cidr` | Source allowed to SSH (CIDR or `*`) | `*` |
| `admin_username` | VM admin user | `ubuntu` |
| `ssh_public_key_path` | Path to the SSH public key | _required_ |

## Outputs

| Output | Description |
| --- | --- |
| `vm_public_ip` | Public IP of the VM — put this in Ansible's `inventory.ini` |
| `vm_id` | VM resource ID |
| `resource_group_name` | Resource group name |
| `vnet_id` | Virtual network ID |
| `subnet_id` | Subnet ID |
| `network_security_group_id` | Network security group ID |

Grab the VM IP for Ansible with:

```bash
terraform output -raw vm_public_ip
```

## Remote state

State is local by default. To store it remotely (shared, locked), create a
resource group, storage account and container once, then uncomment the
`backend "azurerm"` block in `main.tf` and re-run `terraform init`:

```bash
az group create --name agripulse-tfstate-rg --location centralindia
az storage account create --name agripulsetfstate \
  --resource-group agripulse-tfstate-rg --sku Standard_LRS
az storage container create --name tfstate --account-name agripulsetfstate
```

## Notes

- `terraform.tfvars` is committed on purpose — it holds no secrets. State files
  and the SSH private key are gitignored and never leave your machine.
- The VM boots the latest Ubuntu 22.04 LTS image, selected via variables so the
  config is not pinned to a single image build.
