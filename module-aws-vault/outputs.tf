# NLB
output "nlb_dns_name" {
  value       = aws_lb.vault.dns_name
  description = "NLB DNS name"
}

output "nlb_arn" {
  value       = aws_lb.vault.arn
  description = "NLB ARN"
}

# DNS
output "dns_name" {
  value       = var.create_dns_zone ? "${var.dns_record_name}.${var.dns_zone_name}" : null
  description = "Full DNS name for Vault"
}

output "dns_zone_id" {
  value       = var.create_dns_zone ? aws_route53_zone.vault[0].zone_id : null
  description = "Route53 zone ID"
}

# KMS
output "kms_key_id" {
  value       = aws_kms_key.vault.key_id
  description = "KMS key ID for auto-unseal"
}

output "kms_key_arn" {
  value       = aws_kms_key.vault.arn
  description = "KMS key ARN"
}

# DynamoDB
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.vault.name
  description = "DynamoDB table name"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.vault.arn
  description = "DynamoDB table ARN"
}

# IAM
output "iam_role_arn" {
  value       = aws_iam_role.vault.arn
  description = "IAM role ARN"
}

output "instance_profile_name" {
  value       = aws_iam_instance_profile.vault.name
  description = "Instance profile name"
}

# Security Group
output "security_group_id" {
  value       = aws_security_group.vault.id
  description = "Security group ID"
}

# ASG
output "asg_name" {
  value       = aws_autoscaling_group.vault.name
  description = "Auto Scaling Group name"
}

output "launch_template_id" {
  value       = aws_launch_template.vault.id
  description = "Launch template ID"
}

# Target Group
output "target_group_arn" {
  value       = aws_lb_target_group.vault.arn
  description = "Target group ARN"
}

# SSM Endpoints
output "ssm_endpoint_id" {
  value       = var.enable_ssm ? aws_vpc_endpoint.ssm[0].id : null
  description = "SSM VPC endpoint ID"
}
