# Actual values for this deployment.
# No secrets belong here — the SSH private key stays on your machine.
project_name        = "agripulse"
environment         = "dev"
region              = "eu-west-1"
instance_type       = "t3.micro"
app_port            = 3000
vpc_cidr            = "10.0.0.0/16"
subnet_cidr         = "10.0.1.0/24"
ssh_ingress_cidr    = "0.0.0.0/0"
ssh_public_key_path = "~/.ssh/id_rsa.pub"
