variable "transit_gateway_id" {
  type        = string
  description = "TGW ID"
}

variable "route_table_name" {
  type        = string
  description = "Logical name suffix, e.g. hub or spoke"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for tags"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

# map with plan-known keys
variable "routes" {
  type = map(object({
    destination_cidr = string
    attachment_id    = string
  }))
  default = {}
}

# lists are fine; we’ll convert to index-keyed maps in locals
variable "association_attachment_ids" {
  type    = list(string)
  default = []
}

variable "propagation_attachment_ids" {
  type    = list(string)
  default = []
}
