output "tgw_attachment_id" {
  description = "Spoke TGW Attachment ID"
  value       = module.spoke_tgw_attachment.attachment_id
}

output "vpc_cidr" {
  description = "Spoke VPC CIDR"
  value       = local.vpc_cidr
}

output "vpc_id" {
  description = "Spoke VPC ID"
  value       = module.spoke_vpc.vpc_id
}

output "spoke_subnet_keys" {
  value = keys(module.spoke_subnets.subnet_ids_by_key)
}

# ========================================
# Ingress Controller Outputs
# ========================================



# Root-spoke outputs

# EKS cluster info (from EKS module)
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.spoke_eks.cluster_name
}

# Ingress controller Helm info (we know these from locals, not from module outputs)



output "ingress_class" {
  description = "Ingress class used for NGINX ingress controller"
  value       = "nginx"
}

# Load Balancer info (from root data source)




output "ingress_controller_release_name" {
  value = "${local.name_prefix}-ingress-${local.env}"
}

output "ingress_controller_namespace" {
  value = "ingress-${local.env}"
}






# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds_postgres.db_instance_endpoint
}

output "rds_address" {
  description = "RDS address"
  value       = module.rds_postgres.db_instance_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds_postgres.db_instance_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds_postgres.db_instance_name
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds_postgres.security_group_id
}

output "rds_arn" {
  description = "RDS ARN"
  value       = module.rds_postgres.db_instance_arn
}

output "waf_acl_arn" {
  description = "WAFv2 Web ACL ARN created by the WAF module"
  value       = module.waf.acl_arn
}


output "cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  value       = module.iam.cluster_role_arn
}

output "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  value       = module.iam.node_role_arn
}

output "eks_admin_role_arn" {
  description = "IAM role ARN for human EKS admin"
  value       = module.iam.eks_admin_role_arn
}

output "ssm_ec2_role_arn" {
  description = "IAM role ARN for SSM-enabled EC2 instances"
  value       = module.iam.ssm_ec2_role_arn
}

output "ssm_instance_profile_name" {
  description = "Instance profile name for SSM-enabled EC2 instances"
  value       = module.iam.ssm_instance_profile_name
}



output "load_balancer_hostname" {
  description = "DNS name of the ingress NLB/ELB"
  value       = var.enable_ingress_controller && length(data.aws_lb.ingress_nlb) > 0 ? data.aws_lb.ingress_nlb[0].dns_name : null
}

output "load_balancer_arn" {
  description = "ARN of the ingress NLB"
  value       = var.enable_ingress_controller && length(data.aws_lb.ingress_nlb) > 0 ? data.aws_lb.ingress_nlb[0].arn : null
}

output "ingress_nlb_arn" {
  description = "ARN of the ingress NLB (for hub/root remote state etc.)"
  value       = var.enable_ingress_controller && length(data.aws_lb.ingress_nlb) > 0 ? data.aws_lb.ingress_nlb[0].arn : null
}

output "ingress_nlb_dns_name" {
  description = "DNS name of the ingress NLB (for hub/root remote state etc.)"
  value       = var.enable_ingress_controller && length(data.aws_lb.ingress_nlb) > 0 ? data.aws_lb.ingress_nlb[0].dns_name : null
}


output "vpc_link_id" {
  value = module.api_gateway_spoke.vpc_link_id
}

output "stage_name" {
  value = module.api_gateway_spoke.stage_name
}


