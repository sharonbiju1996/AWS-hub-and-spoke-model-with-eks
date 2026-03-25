# module-aws-vpc-endpoints/variables.tf

variable "enable_apigw_endpoint" {
  type        = bool
  default     = false
  description = "Enable API Gateway VPC Endpoint"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "Allowed CIDR blocks for VPC Endpoint"
}

variable "tags" {
  type        = map(string)
  default     = {}
}