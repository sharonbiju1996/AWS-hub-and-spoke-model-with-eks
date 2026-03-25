########################################
# Security Group for Interface Endpoints
########################################

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpce-sg"
  description = "Security group for VPC interface endpoints (EC2/SSM/etc.)"
  vpc_id      = var.vpc_id

  # Allow inbound HTTPS from inside the VPC (nodes, etc.)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound from the endpoints
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpce-sg"
    }
  )
}

locals {
  base_tags = merge(
    var.tags,
    {
      ManagedBy = "terraform"
      Scope     = "vpc-endpoints"
    }
  )
}

########################################
# EC2 Interface Endpoint
########################################

resource "aws_vpc_endpoint" "ec2" {
  count = var.enable_ec2 ? 1 : 0

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ec2"

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]

  private_dns_enabled = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.name_prefix}-ec2-vpce"
    }
  )
}

########################################
# SSM Interface Endpoint
########################################

resource "aws_vpc_endpoint" "ssm" {
  count = var.enable_ssm ? 1 : 0

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ssm"

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]

  private_dns_enabled = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.name_prefix}-ssm-vpce"
    }
  )
}

########################################
# SSMMessages Interface Endpoint
########################################

resource "aws_vpc_endpoint" "ssmmessages" {
  count = var.enable_ssmmessages ? 1 : 0

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ssmmessages"

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]

  private_dns_enabled = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.name_prefix}-ssmmessages-vpce"
    }
  )
}

########################################
# EC2Messages Interface Endpoint
########################################

resource "aws_vpc_endpoint" "ec2messages" {
  count = var.enable_ec2messages ? 1 : 0

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${var.region}.ec2messages"

  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]

  private_dns_enabled = true

  tags = merge(
    local.base_tags,
    {
      Name = "${var.name_prefix}-ec2messages-vpce"
    }
  )
}

