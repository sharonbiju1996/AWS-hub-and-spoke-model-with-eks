# module-aws-tgw-attachment/outputs.tf# module-aws-tgw-attachment/outputs.tf

output "attachment_id" {
  description = "Transit Gateway VPC Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "vpc_id" {
  description = "VPC ID that was attached"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs used for attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.subnet_ids
}

output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.transit_gateway_id
}