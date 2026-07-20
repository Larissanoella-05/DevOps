# AgriPulse — Terraform Infrastructure

Infrastructure as Code for the AgriPulse app. Terraform provisions the network,
a compute VM to run the Docker container, and the security rules around it on AWS.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS credentials configured (`aws configure`, or `AWS_ACCESS_KEY_ID` /
  `AWS_SECRET_ACCESS_KEY` environment variables)
- An SSH key pair. The **public** key path goes in `terraform.tfvars`
  (`ssh_public_key_path`); the matching private key is what Ansible uses later.
  Generate one with `ssh-keygen -t rsa -b 4096` if you don't have it.

## Layout

```
terraform/
├── main.tf            # provider, backend, module composition
├── variables.tf       # input variables (no hardcoded values)
├── outputs.tf         # exposed IPs and resource IDs
├── terraform.tfvars   # actual values for this deployment
└── modules/
    ├── network/       # VPC, public subnet, internet gateway, routing
    ├── security/      # security group: SSH (22) + app port, deny rest
    └── compute/       # Ubuntu VM + key pair
```

## Usage

```bash
cd terraform

# 1. Download providers and initialise the working directory
terraform init

# 2. Preview the changes Terraform will make
terraform plan

# 3. Create the infrastructure
terraform apply

# 4. Tear everything down when you're done
terraform destroy
```

Values are read from `terraform.tfvars` automatically. Override any of them
inline, e.g. `terraform apply -var="environment=prod"`.

## Resources created

| Resource | Purpose |
| --- | --- |
| `aws_vpc` | Isolated virtual network |
| `aws_subnet` | Public subnet the VM lives in |
| `aws_internet_gateway` + `aws_route_table` | Outbound internet access |
| `aws_security_group` | Allow ports 22 and 3000, deny everything else |
| `aws_key_pair` | SSH key installed on the VM |
| `aws_instance` | Ubuntu VM that runs the AgriPulse container |

## Variables

| Variable | Description | Default |
| --- | --- | --- |
| `project_name` | Prefix for resource names and tags | `agripulse` |
| `environment` | Deployment environment | `dev` |
| `region` | AWS region | _required_ |
| `instance_type` | VM size | _required_ |
| `app_port` | App container port | `3000` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `subnet_cidr` | Subnet CIDR block | `10.0.1.0/24` |
| `ssh_ingress_cidr` | CIDR allowed to SSH | `0.0.0.0/0` |
| `ssh_public_key_path` | Path to the SSH public key | _required_ |

## Outputs

| Output | Description |
| --- | --- |
| `vm_public_ip` | Public IP of the VM — put this in Ansible's `inventory.ini` |
| `instance_id` | VM instance ID |
| `vpc_id` | VPC ID |
| `subnet_id` | Subnet ID |
| `security_group_id` | Security group ID |

Grab the VM IP for Ansible with:

```bash
terraform output -raw vm_public_ip
```

## Remote state

State is local by default. To store it remotely (shared, locked), create an S3
bucket and a DynamoDB lock table once, then uncomment the `backend "s3"` block in
`main.tf` and re-run `terraform init`:

```bash
aws s3 mb s3://agripulse-tfstate --region eu-west-1
aws dynamodb create-table \
  --table-name agripulse-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Notes

- `terraform.tfvars` is committed on purpose — it holds no secrets. State files
  and the SSH private key are gitignored and never leave your machine.
- The AMI is looked up dynamically (latest Ubuntu 22.04), so the config is not
  tied to a single region.
