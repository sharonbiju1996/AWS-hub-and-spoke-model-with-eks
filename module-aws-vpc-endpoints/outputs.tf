output "security_group_id" {
  description = "Security group used by all interface endpoints"
  value       = aws_security_group.endpoints.id
}

output "ec2_endpoint_id" {
  description = "ID of the EC2 VPC interface endpoint"
  value       = try(aws_vpc_endpoint.ec2[0].id, null)
}

output "ssm_endpoint_id" {
  description = "ID of the SSM VPC interface endpoint"
  value       = try(aws_vpc_endpoint.ssm[0].id, null)
}

output "ssmmessages_endpoint_id" {
  description = "ID of the SSMMessages VPC interface endpoint"
  value       = try(aws_vpc_endpoint.ssmmessages[0].id, null)
}

output "ec2messages_endpoint_id" {
  description = "ID of the EC2Messages VPC interface endpoint"
  value       = try(aws_vpc_endpoint.ec2messages[0].id, null)
}

