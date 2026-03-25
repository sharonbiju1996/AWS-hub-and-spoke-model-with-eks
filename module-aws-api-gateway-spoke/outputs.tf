output "vpc_link_id" {
  value = aws_api_gateway_vpc_link.this.id
}

output "stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  value = aws_api_gateway_stage.this.arn
}

output "stage_invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}
