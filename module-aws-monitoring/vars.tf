variable "name_prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "volume_size" {
  type        = number
  default     = 50
}

variable "ami_id" {
  type        = string
  default     = ""
}

variable "enable_ssm" {
  type        = bool
  default     = true
}

variable "create_data_volume" {
  type        = bool
  default     = true
}

variable "data_volume_size" {
  type        = number
  default     = 100
}

variable "allowed_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "ssh_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  type        = map(string)
  default     = {}
}