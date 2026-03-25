# module-aws-azdo-agent/main.tf

########################################
# Data Sources
########################################
data "aws_caller_identity" "current" {}

########################################
# IAM Role for Azure DevOps Agent
########################################
resource "aws_iam_role" "azdo_agent" {
  name = "${var.name_prefix}-azdo-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

########################################
# IAM Policy - Secrets Manager Access
########################################
resource "aws_iam_role_policy" "secrets_access" {
  name = "secrets-manager-access"
  role = aws_iam_role.azdo_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"
      }
    ]
  })
}

########################################
# IAM Policy - SSM Access (Optional)
########################################
resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.azdo_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

########################################
# IAM Policy - ECR Access (Optional)
########################################
resource "aws_iam_role_policy_attachment" "ecr" {
  count      = var.enable_ecr_access ? 1 : 0
  role       = aws_iam_role.azdo_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

########################################
# Instance Profile
########################################
resource "aws_iam_instance_profile" "azdo_agent" {
  name = "${var.name_prefix}-azdo-agent-profile"
  role = aws_iam_role.azdo_agent.name
}

########################################
# Security Group
########################################
resource "aws_security_group" "azdo_agent" {
  name        = "${var.name_prefix}-azdo-agent-sg"
  description = "Security group for Azure DevOps Agent"
  vpc_id      = var.vpc_id

  # Outbound - Allow all (agent needs to reach Azure DevOps)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound - SSH (optional)
  dynamic "ingress" {
    for_each = length(var.ssh_cidrs) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_cidrs
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-azdo-agent-sg"
  })
}

########################################
# Launch Template
########################################
resource "aws_launch_template" "azdo_agent" {
  name          = "${var.name_prefix}-azdo-agent-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.azdo_agent.name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups             = [aws_security_group.azdo_agent.id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-azdo-agent"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-azdo-agent-volume"
    })
  }

  tags = var.tags
}

########################################
# Auto Scaling Group
########################################
resource "aws_autoscaling_group" "azdo_agent" {
  name                = "${var.name_prefix}-azdo-agent-asg"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.azdo_agent.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-azdo-agent"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# Scaling Policies (Optional)
########################################
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.enable_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-azdo-agent-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.azdo_agent.name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.enable_scaling_policies ? 1 : 0
  name                   = "${var.name_prefix}-azdo-agent-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.azdo_agent.name
}