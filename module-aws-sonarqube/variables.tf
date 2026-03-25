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

# DNS
variable "create_dns_record" {
  type        = bool
  default     = false
}

variable "dns_zone_id" {
  type        = string
  default     = ""
}

variable "dns_record_name" {
  type        = string
  default     = "sonarqube"
}

# Security
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
