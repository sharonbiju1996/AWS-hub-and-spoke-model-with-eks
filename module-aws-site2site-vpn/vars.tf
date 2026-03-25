variable "customer_gateway_name" {
  description = "Name tag for the Customer Gateway"
  type        = string
}

variable "customer_gateway_ip" {
  description = "Public IP of on-prem VPN device"
  type        = string
  
}

variable "bgp_asn" {
  description = "BGP ASN for the Customer Gateway"
  type        = number
  default     = 65000
}

# -----------------------------
# TGW / VGW selection
# -----------------------------
variable "use_transit_gateway" {
  description = "If true, use Transit Gateway; if false, use VGW attached to a VPC"
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID (when use_transit_gateway = true)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for VGW-based VPN (when use_transit_gateway = false)"
  type        = string
  default     = ""
}

variable "vpn_gateway_name" {
  description = "Name tag for VPN Gateway (VGW), used only when use_transit_gateway = false"
  type        = string
  default     = ""
}

# -----------------------------
# VPN connection settings
# -----------------------------
variable "vpn_connection_name" {
  description = "Name tag for the VPN Connection"
  type        = string
}

variable "static_routes_only" {
  description = "If true, use static routes only. If false, use BGP."
  type        = bool
  default     = true
}

variable "static_routes" {
  description = "Map of name => destination CIDR for VPN static routes"
  type        = map(string)
  default     = {}
}

# -----------------------------
# Tunnel overrides
# Leave empty string to let AWS auto-generate
# -----------------------------
variable "tunnel1_inside_cidr" {
  description = "Inside CIDR for tunnel 1 (optional)"
  type        = string
  default     = ""
}

variable "tunnel1_preshared_key" {
  description = "Pre-shared key for tunnel 1 (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tunnel2_inside_cidr" {
  description = "Inside CIDR for tunnel 2 (optional)"
  type        = string
  default     = ""
}

variable "tunnel2_preshared_key" {
  description = "Pre-shared key for tunnel 2 (optional)"
  type        = string
  sensitive   = true
  default     = ""
}

# -----------------------------
# Tags
# -----------------------------
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
