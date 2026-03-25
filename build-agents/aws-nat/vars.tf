variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID where NAT Gateway will be placed"
  type        = string
}

variable "private_route_table_ids" {
  description = "List of private route table IDs to add NAT routes to"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
