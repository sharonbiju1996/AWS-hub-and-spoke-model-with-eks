output "apigw_vpce_dns" {
  value       = var.enable_apigw_endpoint ? aws_vpc_endpoint.api_gateway[0].dns_entry[0].dns_name : null
  description = "API Gateway VPC Endpoint DNS name"
}

output "apigw_vpce_network_interface_ids" {
  value       = var.enable_apigw_endpoint ? aws_vpc_endpoint.api_gateway[0].network_interface_ids : []
  description = "API Gateway VPC Endpoint network interface IDs"
}

output "apigw_vpce_id" {
  value       = var.enable_apigw_endpoint ? aws_vpc_endpoint.api_gateway[0].id : null
  description = "API Gateway VPC Endpoint ID"
}