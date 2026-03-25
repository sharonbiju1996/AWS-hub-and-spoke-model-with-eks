output "cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  value       = aws_iam_role.cluster_role.arn
}

output "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes"
  value       = aws_iam_role.node_role.arn
}

output "eks_admin_role_arn" {
  description = "IAM role ARN for human/admin EKS access"
  value       = aws_iam_role.eks_admin_role.arn
}

output "ssm_ec2_role_arn" {
  description = "SSM EC2 IAM role ARN"
  value       = aws_iam_role.ssm_ec2_role.arn
}

output "ssm_instance_profile_name" {
  description = "Instance profile name for SSM-enabled EC2 instances"
  value       = aws_iam_instance_profile.ssm_instance_profile.name
}
