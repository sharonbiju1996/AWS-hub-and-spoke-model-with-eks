output "domain_names" {
  description = "Map of custom domain names created"
  value       = { for k, v in aws_api_gateway_domain_name.this : k => v.domain_name }
}

output "regional_domain_names" {
  description = "Map of API Gateway regional domain names (for alias targets)"
  value       = { for k, v in aws_api_gateway_domain_name.this : k => v.regional_domain_name }
}

output "regional_zone_ids" {
  description = "Map of regional hosted zone IDs (for alias targets)"
  value       = { for k, v in aws_api_gateway_domain_name.this : k => v.regional_zone_id }
}
