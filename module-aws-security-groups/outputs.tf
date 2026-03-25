output "vpc_link_security_group_id" {
  description = "VPC Link security group ID"
  value       = aws_security_group.vpc_link.id
}

output "nlb_security_group_id" {
  description = "NLB security group ID (if created)"
  value       = var.create_nlb_sg ? aws_security_group.nlb[0].id : null
}
