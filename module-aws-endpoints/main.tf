# module-aws-vpc-endpoints/main.tf

########################################
# API Gateway VPC Endpoint
########################################
resource "aws_vpc_endpoint" "api_gateway" {
  count               = var.enable_apigw_endpoint ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_apigw[0].id]
  private_dns_enabled = false

  tags = merge(var.tags, {
    Name = "apigw-vpce"
  })
}

########################################
# Security Group for VPC Endpoint
########################################
resource "aws_security_group" "vpce_apigw" {
  count       = var.enable_apigw_endpoint ? 1 : 0
  name        = "vpce-apigw-sg"
  description = "Security group for API Gateway VPC Endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "vpce-apigw-sg"
  })
}