variable "vpc_id" {
  description = "VPC ID to attach the internet gateway"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}


