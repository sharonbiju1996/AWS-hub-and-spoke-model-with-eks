# module-aws-api-gateway-spoke/main.tf

resource "aws_api_gateway_vpc_link" "this" {
  name        = "vpc-link-${var.env}"
  target_arns = [var.nlb_arn]

  tags = merge(var.tags, {
    Environment = var.env
  })
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = var.rest_api_id

  triggers = {
    redeploy = sha256(jsonencode({
      env     = var.env
      nlb_dns = var.nlb_dns
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = var.rest_api_id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.env

  variables = {
    vpcLinkId = aws_api_gateway_vpc_link.this.id
    nlbDns    = var.nlb_dns
  }

  tags = merge(var.tags, {
    Environment = var.env
  })
}

resource "aws_api_gateway_base_path_mapping" "admin" {
  api_id         = var.rest_api_id
  domain_name    = var.domain_names["admin-${var.env}"]
  domain_name_id = var.domain_name_ids["admin-${var.env}"]
  stage_name     = aws_api_gateway_stage.this.stage_name
  base_path      = ""

  depends_on = [aws_api_gateway_stage.this]
}

resource "aws_api_gateway_base_path_mapping" "api" {
  api_id         = var.rest_api_id
  domain_name    = var.domain_names["api-${var.env}"]
  domain_name_id = var.domain_name_ids["api-${var.env}"]
  stage_name     = aws_api_gateway_stage.this.stage_name
  base_path      = ""

  depends_on = [aws_api_gateway_stage.this]
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_enabled ? 1 : 0
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = var.waf_acl_arn
}
