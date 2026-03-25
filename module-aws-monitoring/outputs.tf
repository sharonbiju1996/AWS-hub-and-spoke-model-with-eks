output "instance_id" {
  value       = aws_instance.monitoring.id
  description = "Monitoring EC2 instance ID"
}

output "instance_private_ip" {
  value       = aws_instance.monitoring.private_ip
  description = "Monitoring EC2 private IP"
}

output "security_group_id" {
  value       = aws_security_group.monitoring.id
  description = "Monitoring security group ID"
}

output "iam_role_arn" {
  value       = aws_iam_role.monitoring.arn
  description = "Monitoring IAM role ARN"
}

output "iam_instance_profile_name" {
  value       = aws_iam_instance_profile.monitoring.name
  description = "IAM instance profile name"
}

output "prometheus_url" {
  value       = "http://${aws_instance.monitoring.private_ip}:9090"
  description = "Prometheus URL"
}

output "grafana_url" {
  value       = "http://${aws_instance.monitoring.private_ip}:3000"
  description = "Grafana URL"
}

output "jaeger_url" {
  value       = "http://${aws_instance.monitoring.private_ip}:16686"
  description = "Jaeger UI URL"
}

output "jaeger_collector_endpoint" {
  value       = "${aws_instance.monitoring.private_ip}:14250"
  description = "Jaeger collector gRPC endpoint"
}

output "jaeger_collector_http_endpoint" {
  value       = "${aws_instance.monitoring.private_ip}:14268"
  description = "Jaeger collector HTTP endpoint"
}

output "otlp_grpc_endpoint" {
  value       = "${aws_instance.monitoring.private_ip}:4317"
  description = "OTLP gRPC endpoint"
}

output "otlp_http_endpoint" {
  value       = "${aws_instance.monitoring.private_ip}:4318"
  description = "OTLP HTTP endpoint"
}
