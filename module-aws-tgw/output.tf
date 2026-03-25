# module-aws-tgw/outputs.tf

output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.this.id
}

output "tgw_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.this.arn
}

output "tgw_owner_id" {
  description = "Transit Gateway Owner ID"
  value       = aws_ec2_transit_gateway.this.owner_id
}

output "tgw_route_table_id" {
  description = "Transit Gateway Route Table ID (if created)"
  value       = var.create_tgw_rt ? aws_ec2_transit_gateway_route_table.this[0].id : null
}

output "tgw_association_default_route_table_id" {
  description = "Default association route table ID"
  value       = aws_ec2_transit_gateway.this.association_default_route_table_id
}

output "tgw_propagation_default_route_table_id" {
  description = "Default propagation route table ID"
  value       = aws_ec2_transit_gateway.this.propagation_default_route_table_id
}
