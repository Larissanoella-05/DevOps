# Actual values for this deployment.
# No secrets belong here — the SSH private key stays on your machine.
project_name        = "agripulse"
environment         = "dev"
location            = "centralindia"
vm_size             = "Standard_B2ls_v2"
app_port            = 3000
vnet_cidr           = "10.0.0.0/16"
subnet_cidr         = "10.0.1.0/24"
admin_username      = "ubuntu"
ssh_ingress_cidr    = "*"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
