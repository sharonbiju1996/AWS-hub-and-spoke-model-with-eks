# ========================================
# Monitoring Infrastructure Module
# (Prometheus, Jaeger, Grafana)
# ========================================

data "aws_region" "current" {}

# Ubuntu 22.04 AMI
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
resource "aws_security_group" "monitoring" {
  name        = "${var.name_prefix}-monitoring-sg"
  description = "Monitoring stack security group"
  vpc_id      = var.vpc_id

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Prometheus"
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Grafana"
  }

  # Jaeger Query UI
  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Jaeger UI"
  }

  # Jaeger Collector HTTP
  ingress {
    from_port   = 14268
    to_port     = 14268
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Jaeger Collector HTTP"
  }

  # Jaeger Collector gRPC
  ingress {
    from_port   = 14250
    to_port     = 14250
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "Jaeger Collector gRPC"
  }

  # OTel gRPC
  ingress {
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "OTLP gRPC"
  }

  # OTel HTTP
  ingress {
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
    description = "OTLP HTTP"
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
    Name = "${var.name_prefix}-monitoring-sg"
  })
}

# ========================================
# IAM Role
# ========================================
resource "aws_iam_role" "monitoring" {
  name = "${var.name_prefix}-monitoring-role"

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

resource "aws_iam_role_policy" "monitoring_ec2" {
  name = "monitoring-ec2-describe"
  role = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  count = var.enable_ssm ? 1 : 0

  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.name_prefix}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

# ========================================
# EC2 Instance
# ========================================
resource "aws_instance" "monitoring" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name

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

  # No user_data - Ansible will configure

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-monitoring"
    Role  = "monitoring"
    Stack = "hub"
  })

  volume_tags = merge(var.tags, {
    Name = "${var.name_prefix}-monitoring-root"
  })
}

# ========================================
# EBS Volume for Prometheus Data (optional)
# ========================================
resource "aws_ebs_volume" "prometheus_data" {
  count = var.create_data_volume ? 1 : 0

  availability_zone = aws_instance.monitoring.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-prometheus-data"
  })
}

resource "aws_volume_attachment" "prometheus_data" {
  count = var.create_data_volume ? 1 : 0

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.prometheus_data[0].id
  instance_id = aws_instance.monitoring.id
}

# ========================================
# Route53 DNS Records (optional)
# ========================================
