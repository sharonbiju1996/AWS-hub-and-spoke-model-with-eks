variable "name_prefix" {
  description = "Prefix for EC2 resources (e.g. jc-shared or jc-uat-shared)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/uat/prod/etc)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where instances will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (used to restrict incoming traffic on SGs)"
  type        = string
}

variable "shared_private_subnet_id" {
  description = "Private subnet ID named 'shared' where these EC2 instances will live"
  type        = string
}

variable "instance_type_cache_mq" {
  description = "Instance type for Redis + RabbitMQ server"
  type        = string
  default     = "t3.small"
}

variable "instance_type_mongo" {
  description = "Instance type for MongoDB server"
  type        = string
  default     = "t3.small"
}

variable "enable_public_ip" {
  description = "For debugging only; normally false so instances are private only"
  type        = bool
  default     = false
}

variable "create_cache_mq" {
  type    = bool
  default = true
}

variable "create_mongo" {
  type    = bool
  default = true
}


variable "ssm_instance_profile_name" {
  description = "IAM instance profile name for SSM-enabled EC2 instances"
  type        = string
}


# Add these variables to your existing vars.tf

