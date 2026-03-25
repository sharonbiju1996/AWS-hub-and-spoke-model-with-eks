variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Vault instances"
}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type"
}

variable "cluster_size" {
  type        = number
  default     = 3
  description = "Number of Vault nodes"
}

variable "volume_size" {
  type        = number
  default     = 20
  description = "Root volume size in GB"
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Custom AMI ID (optional)"
}

variable "allowed_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "CIDRs allowed to access Vault API"
}

variable "ssh_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
  description = "CIDRs allowed for SSH"
}

variable "enable_ssm" {
  type        = bool
  default     = true
  description = "Enable SSM Session Manager access"
}

variable "create_dns_zone" {
  type        = bool
  default     = true
  description = "Create Route53 private zone"
}

variable "dns_zone_name" {
  type        = string
  default     = "shared.internal"
  description = "Route53 zone name"
}

variable "dns_record_name" {
  type        = string
  default     = "vault"
  description = "DNS record name for Vault"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}
