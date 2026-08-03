# Staging environment. Same topology as dev, same team access — staging
# exists to validate changes against something closer to prod before they
# actually reach it, not to be cheaper/smaller than dev.
#
# Apply with:
#   terraform workspace select -or-create staging
#   terraform apply -var-file=environments/staging.tfvars
#
# No secrets belong here — the DB password is supplied via
# TF_VAR_db_admin_password and the SSH private key stays on your machine.
project_name = "agripulse"
environment  = "staging"
location     = "centralindia"

vnet_cidr           = "10.1.0.0/16"
public_subnet_cidr  = "10.1.1.0/24"
private_subnet_cidr = "10.1.2.0/24"
db_subnet_cidr      = "10.1.3.0/24"

vm_size         = "Standard_B2ls_v2"
bastion_vm_size = "Standard_B2ts_v2"
app_port        = 3000
admin_username  = "ubuntu"

# Same team, same admin IPs as dev -- update if an ISP reassigns an address.
ssh_ingress_cidrs = [
  "102.22.143.60/32",   # Joshua — runs Terraform
  "197.157.184.193/32", # Emerance — runs the Ansible playbook
  "102.22.178.183/32",  # Larissa — verifying the summative deployment
]

ssh_public_key_path = "~/.ssh/id_ed25519.pub"

extra_ssh_public_keys = [
  # Emerance — runs the Ansible playbook
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5USyQyHVtP6Gdya95qbcaRQ/PbuZa14pwVWKP8pzTCuRp99pIDUrurZcg2ZFssbOEacS10wrM+lO8VnqxcOpKC2q5Gm718aoeKBgbtfsyTZe8E9c4zKPT3wEa8Sk6yYmmOggdGWNEb0asxWznM+KWEfSnid75jJfIiIt7hynyu16lPuVRRoQZBXs6CGVFHmsLj8sSV8+PDDfwi6m1h5AFBZKvvwaVRw+Bw2zso1yw7qgI1az6mWjTn2nDK/BjRb8SkT7hIxrJ5baurMhp6Uiu0Ny2f9Qk91IwtPsvYpKT9QOtL9rRs08GWHLgga3InU2c7WRcvfCCxMCmC7tNjnZGLpUhJ8L6aUhQp2vy7awEHUpUqB6wDe3crHWXxO9cJ/vBnhpLJ9aQVnXeAklVhtVRYhkwkZWiCpivcOis4T014rAeN/rzqWxE6aaYnB1he7pnCBYxqLAIxuaiylYicdeueEe8cLS0e49it1lRoGsg8yVM2PRdfAc/xsc7AajSn9aL0QMl3wnv3ckeZ0PKGfwI+lNqUoRb8OTlzmOgj5F0faHN0KE5WNqA1Giqc4HAsU9lLItgmLzACCW6r8HhVb0Ll3ANYkNXd140JvO1jtL4nmbOXihVRokvHLpu0FO6+N3rWRTwT3bwssHq0qlewiCttyXeEEp1kbw/8YBj7D/Aaw== lenovo@Emerance",
]

db_admin_username = "psqladmin"
db_sku_name       = "B_Standard_B1ms"
db_storage_mb     = 32768

acr_name = "agripulseacr"
