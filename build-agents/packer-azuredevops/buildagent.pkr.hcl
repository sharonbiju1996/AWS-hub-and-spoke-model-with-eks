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

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# ... keep your other variables ...

source "amazon-ebs" "buildagent" {
  region        = var.aws_region
  instance_type = var.instance_type
  ssh_username  = "ubuntu"
  ami_name      = "${var.ami_name}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  associate_public_ip_address = true
  subnet_id = var.subnet_id

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.buildagent"]

  # (Optional) keep your shell scripts for tools
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
      "python311.sh"
    ]
  }

  # ✅ Ansible from your repo folder (for ADO agent setup)
  provisioner "ansible" {
    playbook_file = "../../build-agent/ansible/packer-ado-agent.yml"
  }

  provisioner "shell" {
    scripts = ["cleanup.sh"]
  }
}
