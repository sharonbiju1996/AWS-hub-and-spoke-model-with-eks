output "instance_id" {
  value       = aws_instance.sonarqube.id
  description = "SonarQube EC2 instance ID"
}

output "instance_private_ip" {
  value       = aws_instance.sonarqube.private_ip
  description = "SonarQube EC2 private IP"
}

output "security_group_id" {
  value       = aws_security_group.sonarqube.id
  description = "SonarQube security group ID"
}

output "iam_role_arn" {
  value       = aws_iam_role.sonarqube.arn
  description = "SonarQube IAM role ARN"
}

output "sonarqube_url" {
  value       = "http://${aws_instance.sonarqube.private_ip}:9000"
  description = "SonarQube URL"
}
