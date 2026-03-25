
# ========================================
# Vault Outputs
# ========================================
output "vault_nlb_dns" {
  value = var.enable_vault ? module.vault[0].nlb_dns_name : null
}

output "vault_dns_name" {
  value = var.enable_vault ? module.vault[0].dns_name : null
}

output "vault_kms_key_id" {
  value = var.enable_vault ? module.vault[0].kms_key_id : null
}

output "vault_dynamodb_table" {
  value = var.enable_vault ? module.vault[0].dynamodb_table_name : null
}

output "vault_security_group_id" {
  value = var.enable_vault ? module.vault[0].security_group_id : null
}

output "vault_asg_name" {
  value = var.enable_vault ? module.vault[0].asg_name : null
}

output "vault_dns_zone_id" {
  value = var.enable_vault ? module.vault[0].dns_zone_id : null
}





# ========================================
# SonarQube Outputs
# ========================================
output "sonarqube_instance_id" {
  value       = var.enable_sonarqube ? module.sonarqube[0].instance_id : null
  description = "SonarQube EC2 instance ID"
}

output "sonarqube_private_ip" {
  value       = var.enable_sonarqube ? module.sonarqube[0].instance_private_ip : null
  description = "SonarQube private IP"
}

output "sonarqube_security_group_id" {
  value       = var.enable_sonarqube ? module.sonarqube[0].security_group_id : null
  description = "SonarQube security group ID"
}

output "sonarqube_iam_role_arn" {
  value       = var.enable_sonarqube ? module.sonarqube[0].iam_role_arn : null
  description = "SonarQube IAM role ARN"
}

output "sonarqube_url" {
  value       = var.enable_sonarqube ? module.sonarqube[0].sonarqube_url : null
  description = "SonarQube URL"
}