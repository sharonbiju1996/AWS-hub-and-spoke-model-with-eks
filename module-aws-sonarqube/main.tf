# ========================================
# SonarQube Infrastructure Module (Simple)
# EC2 only - PostgreSQL installed via Ansible
# ========================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ========================================
# Security Group
# ========================================
resource "aws_security_group" "sonarqube" {
  name        = "${var.name_prefix}-sonarqube-sg"
  description = "SonarQube security group"
  vpc_id      = var.vpc_id

  # SonarQube Web
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "SonarQube Web"
  }

  # Node Exporter
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Node Exporter"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidrs
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sonarqube-sg"
  })
}

# ========================================
# IAM Role
# ========================================
resource "aws_iam_role" "sonarqube" {
  name = "${var.name_prefix}-sonarqube-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "sonarqube_ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.sonarqube.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "sonarqube" {
  name = "${var.name_prefix}-sonarqube-profile"
  role = aws_iam_role.sonarqube.name
}

# ========================================
# EC2 Instance
# ========================================
resource "aws_instance" "sonarqube" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.sonarqube.id]
  iam_instance_profile   = aws_iam_instance_profile.sonarqube.name

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-sonarqube"
    Role  = "sonarqube"
    Stack = "shared"
  })
}

# ========================================
# Route53 DNS (optional)
# ========================================
