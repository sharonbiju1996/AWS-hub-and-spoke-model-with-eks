# module-aws-azdo-agent/outputs.tf

output "asg_name" {
  value = aws_autoscaling_group.azdo_agent.name
}

output "asg_arn" {
  value = aws_autoscaling_group.azdo_agent.arn
}

output "launch_template_id" {
  value = aws_launch_template.azdo_agent.id
}

output "security_group_id" {
  value = aws_security_group.azdo_agent.id
}

output "iam_role_arn" {
  value = aws_iam_role.azdo_agent.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.azdo_agent.name
}