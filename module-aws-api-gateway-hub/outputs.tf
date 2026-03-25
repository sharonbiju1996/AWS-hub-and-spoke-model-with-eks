# module-aws-api-gateway-hub/outputs.tf

output "rest_api_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "API Gateway REST API ID"
}

output "rest_api_execution_arn" {
  value       = aws_api_gateway_rest_api.this.execution_arn
  description = "API Gateway execution ARN"
}

output "execute_api_domain" {
  value       = "${aws_api_gateway_rest_api.this.id}.execute-api.data.aws_region.current.name.amazonaws.com"
  description = "API Gateway execute-api domain"
}

output "api_gateway_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "API Gateway ID (alias for rest_api_id)"
}
