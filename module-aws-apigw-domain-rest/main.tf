locals {
  # Add all domains you want managed by this module
  domain_names = toset(var.domain_names)
}

resource "aws_api_gateway_domain_name" "this" {
  for_each = local.domain_names

  domain_name              = each.value
  regional_certificate_arn = var.acm_cert_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Optional default base path mapping for EACH domain
resource "aws_api_gateway_base_path_mapping" "default" {
  for_each = var.create_default_base_path_mapping ? aws_api_gateway_domain_name.this : {}

  api_id      = var.default_api_id
  stage_name  = var.default_stage_name
  domain_name = each.value.domain_name
  base_path   = ""
}

# Route53 alias record for EACH domain
#resource "aws_route53_record" "domain_alias" {
  #for_each = aws_api_gateway_domain_name.this

  #zone_id         = var.hosted_zone_id
  #name            = each.value.domain_name
  #type            = "A"
  #allow_overwrite = true

  #alias {
    #name                   = each.value.regional_domain_name
    #zone_id                = each.value.regional_zone_id
    #evaluate_target_health = false
  #}
#}
