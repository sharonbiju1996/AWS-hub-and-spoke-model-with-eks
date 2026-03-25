# module-aws-routetable/outputs.tf

output "route_table_ids" {
  description = "Map of route table names to their IDs"
  value       = { for k, v in aws_route_table.this : k => v.id }
}

output "route_table_arns" {
  description = "Map of route table names to their ARNs"
  value       = { for k, v in aws_route_table.this : k => v.arn }
}

output "route_ids" {
  description = "Map of route keys to route IDs"
  value       = { for k, v in aws_route.this : k => v.id }
}

output "association_ids" {
  description = "Map of association keys to association IDs"
  value       = { for k, v in aws_route_table_association.this : k => v.id }
}

output "all_route_tables" {
  description = "Complete route table resources"
  value       = aws_route_table.this
}