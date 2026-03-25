output "vpc_id" {
  description = "Build VPC ID"
  value       = module.build_vpc.vpc_id
}

output "vpc_cidr" {
  description = "Build VPC CIDR"
  value       = var.vpc_cidr
}

output "subnet_ids" {
  description = "Build subnet IDs"
  value       = module.build_subnets.subnet_ids_by_key
}

output "tgw_attachment_id" {
  description = "TGW attachment ID for Build VPC"
  value       = module.build_tgw_attachment.attachment_id
}
