variable "attachment_id" {
  description = "TGW VPC attachment ID for this spoke"
  type        = string
}

variable "hub_route_table_id" {
  description = "ID of the TGW HUB route table (for propagation)"
  type        = string
}

variable "spoke_route_table_id" {
  description = "ID of the TGW route table to associate with"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of this VPC (for adding routes in other route tables)"
  type        = string
  default     = ""
}

variable "add_route_to_route_tables" {
  description = "Map of route table IDs where route to this VPC should be added"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags (optional)"
  type        = map(string)
  default     = {}
}
