variable "name_prefix" {
  description = "Prefix for naming VPC endpoints and security group"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for interface endpoints (EKS worker subnets)"
  type        = list(string)
}

variable "region" {
  description = "AWS region (used to build service names)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR of the VPC, used to restrict SG ingress"
  type        = string
}

variable "enable_ec2" {
  description = "Create EC2 interface endpoint"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Create SSM interface endpoint"
  type        = bool
  default     = true
}

variable "enable_ssmmessages" {
  description = "Create SSMMessages interface endpoint"
  type        = bool
  default     = true
}

variable "enable_ec2messages" {
  description = "Create EC2Messages interface endpoint"
  type        = bool
  default     = true
}

