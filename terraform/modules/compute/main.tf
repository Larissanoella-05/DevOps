# Look up the latest Ubuntu 22.04 image so we never pin a region-specific AMI.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.this.key_name

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_tokens = "required" # require IMDSv2
  }

  tags = { Name = "${var.name}-vm" }
}
