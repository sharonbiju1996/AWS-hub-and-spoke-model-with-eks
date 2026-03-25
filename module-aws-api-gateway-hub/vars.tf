# module-aws-api-gateway-hub/variables.tf

variable "vpc_endpoint_id" {
  type        = string
  description = "VPC Endpoint ID for API Gateway"
}

variable "tags" {
  type    = map(string)
  default = {}
}
