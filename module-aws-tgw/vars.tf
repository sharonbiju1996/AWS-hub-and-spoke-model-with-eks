variable "name_prefix" {
  description = "Prefix for TGW naming (e.g. jc-hub)"
  type        = string
}

variable "tags" {
  description = "Common tags for all TGW resources"
  type        = map(string)
  default     = {}
}

variable "amazon_side_asn" {
  description = "BGP ASN for the AWS side of the TGW"
  type        = number
  default     = 64512
}

variable "create_tgw_rt" {
  description = "Whether to create a TGW route table"
  type        = bool
  default     = true
}



variable "auto_accept_shared_attachments" {
  type        = string
  default     = "enable"
  description = "Auto accept shared attachments"
}

variable "default_route_table_association" {
  type        = string
  default     = "disable"
  description = "Default route table association"
}

variable "default_route_table_propagation" {
  type        = string
  default     = "disable"
  description = "Default route table propagation"
}

variable "dns_support" {
  type        = string
  default     = "enable"
  description = "DNS support for Transit Gateway"
}

variable "vpn_ecmp_support" {
  type        = string
  default     = "enable"
  description = "VPN ECMP support for Transit Gateway"
}

