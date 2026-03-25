packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.0"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
}

# -----------------------------
# Variables
# -----------------------------
variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_name" {
  type    = string
  default = "buildagent-ubuntu-2204"
}

variable "subnet_id" {
  type    = string
  default = "subnet-0a461e2b54fc6280f"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0a8508b4e4a11a35c"
}

# -----------------------------
# Source: amazon-ebs
# -----------------------------
source "amazon-ebs" "buildagent" {
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ami_name      = "${var.ami_name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  associate_public_ip_address = true
  subnet_id = var.subnet_id
  vpc_id    = var.vpc_id

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  tags = {
    Owner = "Enfin"
    Role  = "build-agent"
  }
}

# -----------------------------
# Build
# -----------------------------
build {
  sources = ["source.amazon-ebs.buildagent"]

  provisioner "shell" {
    scripts = [
      "install.sh",
      "install-az-cli.sh",
      "install-aws-cli.sh",
      "install-kubectl.sh",
      "install-helm.sh",
      "install-terraform.sh",
      "install-gitleaks.sh",
      "install-checkov.sh",
      "install-trivy.sh",
      "install-java.sh",
      "install-docker.sh",
      "python311.sh",
      "install-azdo-agent.sh"
    ]
  }

  provisioner "shell" {
    scripts = ["cleanup.sh"]
  }
}
