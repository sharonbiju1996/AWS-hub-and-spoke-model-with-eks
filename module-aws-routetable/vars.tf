variable "vpc_id" {
  description = "VPC ID where route tables will be created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming route tables"
  type        = string
}

variable "tags" {
  description = "Tags to apply to route tables"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Map of subnet keys to subnet IDs for associations"
  type        = map(string)
}

variable "route_tables" {
  description = <<EOT
Map of route tables and their routes.
Example:
{
  main = {
    routes = [
      {
        destination = "0.0.0.0/0"
        gateway_id  = "igw-123456"
      }
    ]
  }
}
EOT
  type = map(object({
    routes = list(object({
      destination               = string
      gateway_id                = optional(string)
      nat_gateway_id            = optional(string)
      transit_gateway_id        = optional(string)
      vpc_endpoint_id           = optional(string)
      vpc_peering_connection_id = optional(string)
      egress_only_gateway_id    = optional(string)
      network_interface_id      = optional(string)
      local_gateway_id          = optional(string)
      carrier_gateway_id        = optional(string)
      core_network_arn          = optional(string)
    }))
  }))
}

variable "associations" {
  description = <<EOT
Map of route table associations.
Example:
{
  "bastion-public" = {
    subnet_key = "bastion"
    rt_key     = "public"
  }
}
EOT
  type = map(object({
    subnet_key = string
    rt_key     = string
  }))
}