output "asg_name" {
  description = "Name of the autoscaling group for build agents"
  value       = aws_autoscaling_group.azdo.name
}

output "security_group_id" {
  description = "ID of the security group used by agents"
  value       = aws_security_group.azdo.id
}

output "launch_template_id" {
  description = "ID of the launch template for agents"
  value       = aws_launch_template.azdo.id
}

output "iam_role_name" {
  description = "Name of the IAM role used by agents (SSM role)"
  value       = aws_iam_role.ssm.name
}
