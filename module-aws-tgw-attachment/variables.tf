# module-aws-tgw-attachment/variables.tf

variable "transit_gateway_id" {
  description = "Transit Gateway ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the attachment (typically one per AZ)"
  type        = list(string)
}

variable "name_prefix" {
  description = "Prefix for naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

variable "appliance_mode_support" {
  description = "Enable appliance mode (for firewall/inspection)"
  type        = bool
  default     = false
}

variable "default_route_table_association" {
  description = "Enable default route table association"
  type        = bool
  default     = false
}

variable "default_route_table_propagation" {
  description = "Enable default route table propagation"
  type        = bool
  default     = false
}
