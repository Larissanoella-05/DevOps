# Actual values for this deployment.
# No secrets belong here — the SSH private key stays on your machine.
project_name   = "agripulse"
environment    = "dev"
location       = "centralindia"
vm_size        = "Standard_B2ls_v2"
app_port       = 3000
vnet_cidr      = "10.0.0.0/16"
subnet_cidr    = "10.0.1.0/24"
admin_username = "ubuntu"
# SSH is restricted to the team's admin IPs rather than left open to the internet.
# Update these if an ISP reassigns an address.
ssh_ingress_cidrs = [
  "102.22.143.60/32",   # Joshua — runs Terraform
  "197.157.184.193/32", # Emerance — runs the Ansible playbook
]
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

# Teammate public keys granted SSH access to the VM. These are public halves only,
# so they are safe to commit — no private key ever leaves its owner's machine.
extra_ssh_public_keys = [
  # Emerance — runs the Ansible playbook
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5USyQyHVtP6Gdya95qbcaRQ/PbuZa14pwVWKP8pzTCuRp99pIDUrurZcg2ZFssbOEacS10wrM+lO8VnqxcOpKC2q5Gm718aoeKBgbtfsyTZe8E9c4zKPT3wEa8Sk6yYmmOggdGWNEb0asxWznM+KWEfSnid75jJfIiIt7hynyu16lPuVRRoQZBXs6CGVFHmsLj8sSV8+PDDfwi6m1h5AFBZKvvwaVRw+Bw2zso1yw7qgI1az6mWjTn2nDK/BjRb8SkT7hIxrJ5baurMhp6Uiu0Ny2f9Qk91IwtPsvYpKT9QOtL9rRs08GWHLgga3InU2c7WRcvfCCxMCmC7tNjnZGLpUhJ8L6aUhQp2vy7awEHUpUqB6wDe3crHWXxO9cJ/vBnhpLJ9aQVnXeAklVhtVRYhkwkZWiCpivcOis4T014rAeN/rzqWxE6aaYnB1he7pnCBYxqLAIxuaiylYicdeueEe8cLS0e49it1lRoGsg8yVM2PRdfAc/xsc7AajSn9aL0QMl3wnv3ckeZ0PKGfwI+lNqUoRb8OTlzmOgj5F0faHN0KE5WNqA1Giqc4HAsU9lLItgmLzACCW6r8HhVb0Ll3ANYkNXd140JvO1jtL4nmbOXihVRokvHLpu0FO6+N3rWRTwT3bwssHq0qlewiCttyXeEEp1kbw/8YBj7D/Aaw== lenovo@Emerance",
]
