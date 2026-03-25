# root-hub/variables.tf

# ========================================
# Core / Region
# ========================================
variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region where resources will be created"
}

variable "environment" {
  type        = string
  default     = "hub"
  description = "Environment name (will use workspace if not set)"
}

# ========================================
# Naming & Tagging
# ========================================
variable "name_prefix_override" {
  type        = string
  default     = null
  description = "Override the auto-generated name prefix (jc-{env})"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base tags applied to all resources"
}

variable "application_name" {
  type        = string
  default     = "jcapp"
  description = "Application name for tagging"
}

variable "owner" {
  type        = string
  default     = "enfin"
  description = "Owner tag value"
}

# ========================================
# Network - Hub VPC
# ========================================
variable "vpc_cidr" {
  type        = string
  default     = "10.58.0.0/16"
  description = "CIDR for the hub VPC"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "How many AZs to consider from the region's available list"
}

# ========================================
# Subnets
# ========================================
variable "subnets" {
  description = "Hub subnet definitions map"
  type = map(object({
    cidr     = string
    az_index = number
    type     = string
  }))

  default = {
    bastion       = { cidr = "10.58.0.0/20", az_index = 0, type = "private" }
    vm            = { cidr = "10.58.16.0/20", az_index = 0, type = "private" }
    vpn           = { cidr = "10.58.32.0/20", az_index = 0, type = "vpn" }
    api           = { cidr = "10.58.48.0/20", az_index = 0, type = "private" }
    gateway       = { cidr = "10.58.64.0/20", az_index = 0, type = "private" }
    firewall      = { cidr = "10.58.80.0/20", az_index = 0, type = "firewall" }
    public_subnet = { cidr = "10.58.96.0/20", az_index = 0, type = "public" }
    public_subnet1 = { cidr = "10.58.112.0/20", az_index = 0, type = "public" }  # Keep original
    public_subnet2 = { cidr = "10.58.128.0/20", az_index = 1, type = "public" }



    
  }
}

# ========================================
# NAT Gateway
# ========================================
variable "enable_nat" {
  type        = bool
  default     = true
  description = "Enable NAT Gateway(s) in hub"
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "Create a single NAT gateway (true) or per-AZ (false)"
}

# ========================================
# Transit Gateway
# ========================================
variable "tgw_amazon_side_asn" {
  type        = number
  default     = 64512
  description = "BGP ASN for the Amazon side of the Transit Gateway"
}

variable "tgw_auto_accept_shared_attachments" {
  type        = string
  default     = "enable"
  description = "Auto accept shared attachments"
}

variable "tgw_default_route_table_association" {
  type        = string
  default     = "disable"
  description = "Default route table association (disable to use custom route tables)"
}

variable "tgw_default_route_table_propagation" {
  type        = string
  default     = "disable"
  description = "Default route table propagation (disable to use custom route tables)"
}

variable "tgw_dns_support" {
  type        = string
  default     = "enable"
  description = "DNS support for Transit Gateway"
}

variable "tgw_vpn_ecmp_support" {
  type        = string
  default     = "enable"
  description = "VPN ECMP support for Transit Gateway"
}

# ========================================
# Transit Gateway Attachments
# ========================================
variable "hub_appliance_mode_support" {
  type        = bool
  default     = true
  description = "Enable appliance mode for hub (needed for firewall inspection)"
}

variable "hub_tgw_route_table_association" {
  type        = bool
  default     = true
  description = "Associate hub attachment with custom TGW route table"
}

variable "hub_tgw_route_table_propagation" {
  type        = bool
  default     = true
  description = "Propagate hub routes to TGW route tables"
}

# ========================================
# Network Routing - External Networks
# ========================================
variable "spoke_vpc_cidrs" {
  description = "Map of spoke VPC CIDRs for TGW routing"
  type        = map(string)
  default = {
    spoke1 = "10.59.0.0/16"
    spoke2 = "10.60.0.0/16"
  }
}



variable "enable_onprem_routing" {
  description = "Enable routing to on-premises network"
  type        = bool
  default     = false
}

# ========================================
# Firewall
# ========================================
variable "enable_firewall" {
  type        = bool
  default     = true
  description = "Enable AWS Network Firewall"
}

variable "firewall_policy_stateless_default_actions" {
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
  description = "Stateless default actions for firewall policy"
}

variable "firewall_policy_stateless_fragment_default_actions" {
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
  description = "Stateless fragment default actions"
}

variable "firewall_rule_capacity" {
  type        = number
  default     = 100
  description = "Capacity for firewall rule group"
}

# root-hub/variables.tf

variable "spoke_attachments" {
  description = "Map of spoke attachments to create routes for"
  type = map(object({
    vpc_cidr      = string
    attachment_id = string
  }))
  default = {}
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
  default     = "terraform-state-bucket-jc1" # ← Change this!
}

variable "include_spoke_dev_in_hub_rt" {
  type        = bool
  default     = false
  description = "Add dev spoke CIDR→attachment route in the HUB TGW RT"
}


# On-prem and VPN



variable "onprem_cidrs" {
  description = "On-premises network CIDR blocks"
  type        = list(string)
  default     = [
    "172.16.0.0/16",
    "10.50.0.0/16"
  ]
}

variable "customer_gateway_ip" {
  description = "Public IP of on-prem VPN device"
  type        = string
  default = "20.246.182.156"
}

variable "customer_gateway_bgp_asn" {
  description = "BGP ASN of on-prem device"
  type        = number
  default     = 65001
}



variable "use_transit_gateway" {
  description = "If true, use TGW; if false, use VGW"
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "TGW ID when using TGW termination"
  type        = string
  default     = ""
}

variable "vpn_vpc_id" {
  description = "VPC ID when using VGW termination"
  type        = string
  default     = ""
}

variable "vpn_gateway_name" {
  description = "Name for VGW (only used when TGW is false)"
  type        = string
  default     = ""
}

variable "vpn_static_routes_only" {
  description = "Use static routing or BGP"
  type        = bool
  default     = true
}

variable "tunnel1_inside_cidr" {
  type        = string
  default     = ""
}

variable "tunnel1_preshared_key" {
  type        = string
  sensitive   = true
  default     = ""
}

variable "tunnel2_inside_cidr" {
  type        = string
  default     = ""
}

variable "tunnel2_preshared_key" {
  type        = string
  sensitive   = true
  default     = ""
}

variable "spoke_supernet_cidrs" {
  description = "List of CIDRs (spokes or supernets) that should route from hub VPC to TGW"
  type        = list(string)

  default = [
    "10.59.0.0/16", # dev
    "10.60.0.0/16", # uat
    "10.61.0.0/16", # prod
    
    # add more here as needed
  ]
}

variable "shared_cidr" {
  description = "shared services VPC CIDR"
  type        = string
  default     = "10.62.0.0/16"
}
variable "build_cidr" {
  description = "Build VPC CIDR"
  type        = string
  default     = "10.63.0.0/16"
  }


# ========================================
# Monitoring Variables (root-hub/monitoring-vars.tf)
# Add these to your existing vars.tf or create this file
# ========================================

# ========================================
# Monitoring Enable
# ========================================
variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "Deploy monitoring stack (Prometheus, Jaeger, Grafana)"
}

# ========================================
# Monitoring EC2
# ========================================
variable "monitoring_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Monitoring EC2 instance type"
}

variable "monitoring_volume_size" {
  type        = number
  default     = 50
  description = "Root volume size in GB"
}

variable "monitoring_create_data_volume" {
  type        = bool
  default     = true
  description = "Create separate EBS volume for Prometheus data"
}

variable "monitoring_data_volume_size" {
  type        = number
  default     = 100
  description = "Data volume size in GB"
}

# ========================================
# Monitoring DNS
# ========================================
variable "monitoring_create_dns" {
  type        = bool
  default     = true
  description = "Create Route53 DNS records for monitoring"
}






# root-hub/variables.tf (add these)

variable "wildcard_cert_arn" {
  type        = string
  default     = "arn:aws:acm:us-west-2:289880680686:certificate/101ccb5b-a014-46e7-96e7-e88127cbf894"
  description = "ACM certificate ARN for wildcard domain"
}

variable "waf_enabled" {
  type        = bool
  default     = false
  description = "Enable WAF"
}