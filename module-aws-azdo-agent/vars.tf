# module-aws-azdo-agent/variables.tf

variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ASG"
}

variable "ami_id" {
  type        = string
  description = "Packer AMI ID for Azure DevOps Agent"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "secret_name" {
  type        = string
  default     = "azdo/agent/config"
  description = "Secrets Manager secret name"
}

variable "key_name" {
  type        = string
  default     = ""
  description = "SSH key name (optional)"
}

variable "volume_size" {
  type        = number
  default     = 50
  description = "Root volume size in GB"
}

variable "associate_public_ip" {
  type        = bool
  default     = false
  description = "Associate public IP"
}

# ASG Settings
variable "desired_capacity" {
  type        = number
  default     = 2
  description = "Desired number of agents"
}

variable "min_size" {
  type        = number
  default     = 1
  description = "Minimum number of agents"
}

variable "max_size" {
  type        = number
  default     = 5
  description = "Maximum number of agents"
}

# Security
variable "ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed for SSH"
}

# Optional Features
variable "enable_ssm" {
  type        = bool
  default     = true
  description = "Enable SSM Session Manager"
}

variable "enable_ecr_access" {
  type        = bool
  default     = true
  description = "Enable ECR access for Docker builds"
}

variable "enable_scaling_policies" {
  type        = bool
  default     = false
  description = "Enable auto scaling policies"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}