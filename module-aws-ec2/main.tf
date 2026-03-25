terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

########################################
# Ubuntu 22.04 AMI (Canonical)
########################################

data "aws_ami" "ubuntu_2204" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}



########################################
# Security Groups
########################################

# SG for Redis + RabbitMQ
resource "aws_security_group" "cache_mq_sg" {
  name        = "${var.name_prefix}-cache-mq-sg-${var.environment}"
  description = "Allow Redis + RabbitMQ inside VPC"
  vpc_id      = var.vpc_id

  # Redis 6379
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RabbitMQ AMQP 5672
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RabbitMQ management UI 15672 (still private, only from VPC)
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound (to NAT Gateway / VPC Endpoints / internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-cache-mq-sg-${var.environment}"
    Environment = var.environment
  }
}

# SG for MongoDB
resource "aws_security_group" "mongo_sg" {
  name        = "${var.name_prefix}-mongo-sg-${var.environment}"
  description = "Allow MongoDB inside VPC"
  vpc_id      = var.vpc_id

  # MongoDB port 27017
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-mongo-sg-${var.environment}"
    Environment = var.environment
  }
}

########################################
# User data (Ubuntu 22 + Docker + SSM + containers)
########################################

locals {
  cache_mq_user_data = <<-EOF
    #!/bin/bash
    set -xe

    # Update packages
    apt-get update -y

    # Install Docker
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    # Install SSM Agent on Ubuntu 22.04
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

    # Pull images
    docker pull redis:6
    docker pull rabbitmq:3.9-management

    # Run Redis 6
    docker run -d \
      --name redis6 \
      --restart unless-stopped \
      -p 6379:6379 \
      redis:6

    # Run RabbitMQ 3.9 with management UI
    docker run -d \
      --name rabbitmq39 \
      --restart unless-stopped \
      -p 5672:5672 \
      -p 15672:15672 \
      rabbitmq:3.9-management
  EOF

  mongo_user_data = <<-EOF
    #!/bin/bash
    set -xe

    apt-get update -y
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    # Install SSM Agent
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

    # Pull MongoDB 7.0
    docker pull mongo:7.0

    # Run MongoDB 7.0 with simple root user (change password in real env)
    docker run -d \
      --name mongo7 \
      --restart unless-stopped \
      -p 27017:27017 \
      -e MONGO_INITDB_ROOT_USERNAME=admin \
      -e MONGO_INITDB_ROOT_PASSWORD=changeme \
      mongo:7.0
  EOF
}

########################################
# EC2: Redis + RabbitMQ
########################################

resource "aws_instance" "cache_mq" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type_cache_mq
  subnet_id                   = var.shared_private_subnet_id
  associate_public_ip_address = var.enable_public_ip

  vpc_security_group_ids = [aws_security_group.cache_mq_sg.id]

  iam_instance_profile = var.ssm_instance_profile_name 
  user_data = local.cache_mq_user_data

  tags = {
    Name        = "${var.name_prefix}-cache-mq-${var.environment}"
    Role        = "redis-rabbitmq"
    Environment = var.environment
  }
}

########################################
# EC2: MongoDB 7.0
########################################

resource "aws_instance" "mongo" {
  ami                         = data.aws_ami.ubuntu_2204.id
  instance_type               = var.instance_type_mongo
  subnet_id                   = var.shared_private_subnet_id
  associate_public_ip_address = var.enable_public_ip

  vpc_security_group_ids = [aws_security_group.mongo_sg.id]

  iam_instance_profile = var.ssm_instance_profile_name 

  user_data = local.mongo_user_data

  tags = {
    Name        = "${var.name_prefix}-mongo-${var.environment}"
    Role        = "mongodb"
    Environment = var.environment
  }
}


# Add this at the end of your existing module-aws-ec2/main.tf

