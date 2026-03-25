




output "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes"
  value       = var.node_role_arn
}



output "cluster_name" {
  value = var.enabled ? aws_eks_cluster.this[0].name : null
}

output "cluster_arn" {
  value = var.enabled ? aws_eks_cluster.this[0].arn : null
}

output "cluster_endpoint" {
  value = var.enabled ? aws_eks_cluster.this[0].endpoint : null
}

output "cluster_ca" {
  value = var.enabled ? aws_eks_cluster.this[0].certificate_authority[0].data : null
}





