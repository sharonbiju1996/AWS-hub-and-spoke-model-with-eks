# root-spoke/variables.tf

# ========================================
# Core / Region
# ========================================
variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region for spokes"
}

variable "environment" {
  type        = string
  default     = null
  description = "Environment name (will use workspace if not set)"
}

# ========================================
# Naming & Tagging
# ========================================
variable "name_prefix_override" {
  type        = string
  default     = null
  description = "Override the auto-generated name prefix"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base tags applied to all spoke resources"
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
# Network - Spoke VPC
# ========================================
variable "vpc_cidr_map" {
  description = "Map of workspace -> VPC CIDR for spokes"
  type        = map(string)
  default = {
    default = "10.59.0.0/16"
    dev     = "10.59.0.0/16"
    uat     = "10.60.0.0/16"
    prod    = "10.61.0.0/16"
    spoke1  = "10.59.0.0/16"
    spoke2  = "10.62.0.0/16"
  }
}

variable "az_count" {
  type        = number
  default     = 2
  description = "How many AZs to consider"
}

# ========================================
# Subnets
# ========================================





# ========================================
# Hub and External Networks
# ========================================
variable "hub_vpc_cidr" {
  description = "Hub VPC CIDR for routing"
  type        = string
  default     = "10.58.0.0/16"
}

variable "hub_tgw_name" {
  description = "Hub Transit Gateway name tag to lookup"
  type        = string
  default     = "jc-hub-tgw"
}

variable "hub_tgw_rt_spoke_name" {
  description = "Hub TGW Spoke Route Table name tag to lookup"
  type        = string
  default     = "jc-hub-tgw-rt-spoke"
}

variable "onprem_cidr" {
  description = "On-premises network CIDR"
  type        = string
  default     = "172.16.0.0/16"
}

variable "shared_cidr" {
  description = "On-premises network CIDR"
  type        = string
  default     = "10.62.0.0/16"
}

variable "build_cidr" {
  description = "Build VPC CIDR for routing"
  type        = string
  default     = "10.63.0.0/16"
}

# ========================================
# Routing Configuration
# ========================================
variable "enable_internet_via_tgw" {
  description = "Route internet traffic (0.0.0.0/0) through TGW to hub"
  type        = bool
  default     = true
}

variable "enable_hub_routing" {
  description = "Enable routing to hub VPC"
  type        = bool
  default     = true
}

variable "enable_build_routing" {
  description = "Enable routing to build VPC"
  type        = bool
  default     = true
}

variable "enable_onprem_routing" {
  description = "Enable routing to on-premises network"
  type        = bool
  default     = true
}

variable "enable_shared_routing" {
  description = "Enable routing to on-premises network"
  type        = bool
  default     = true
}

variable "additional_tgw_routes" {
  description = "Additional CIDR blocks to route through TGW"
  type        = list(string)
  default     = []
}

# ========================================
# Transit Gateway Attachments
# ========================================
variable "tgw_attachment_subnet_key" {
  description = "Subnet key to use for TGW attachment"
  type        = string
  default     = "eks"
}

variable "spoke_appliance_mode_support" {
  type        = bool
  default     = false
  description = "Enable appliance mode for spoke (typically false)"
}

# ========================================
# Route Table Configuration
# ========================================
variable "eks_route_to_tgw" {
  description = "Enable TGW routing for AKS subnet"
  type        = bool
  default     = true
}

variable "db_isolated" {
  description = "Keep DB subnet isolated (no external routes)"
  type        = bool
  default     = true
}

variable "shared_route_to_tgw" {
  description = "Enable TGW routing for shared subnet"
  type        = bool
  default     = true
}

variable "nlb_route_to_tgw" {
  description = "Enable TGW routing for NLB subnet"
  type        = bool
  default     = false
}

# ========================================
# Transit Gateway Attachment Variables
# ========================================

variable "spoke_tgw_route_table_association" {
  type        = bool
  default     = "false"
  description = "Enable or disable default route table association for spoke TGW attachment"
}

variable "spoke_tgw_route_table_propagation" {
  type        = bool
  default     = "false"
  description = "Enable or disable default route table propagation for spoke TGW attachment"
}

#=====================================================
# Common ingress settings
#====================================================
variable "ingress_chart_version" {
  type    = string
  default = "4.11.0"
}

variable "ingress_namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "ingress_create_namespace" {
  type    = bool
  default = true
}

variable "ingress_load_balancer_scheme" {
  description = "\"internal\" or \"internet-facing\""
  type        = string
  default     = "internal"
}

# Autoscaling
variable "ingress_autoscaling_enabled" {
  type    = bool
  default = true
}

variable "ingress_autoscaling_min_replicas" {
  type    = number
  default = 2
}

variable "ingress_autoscaling_max_replicas" {
  type    = number
  default = 10
}

variable "ingress_autoscaling_target_cpu" {
  type    = number
  default = 80
}

# Tenant host domain per env (dev here)
variable "dev_tenant_domain" {
  description = "Base domain for dev tenant wildcard"
  type        = string
  default     = "dev.idukkiflavours.shop"
}


# Environment name
variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

# Domain name for the application
variable "domain_name" {
  description = "Base domain name for API Gateway custom domain"
  type        = string
  default     = "idukkiflavours.shop"
}

# API Gateway throttling settings
variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 5000
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 10000
}


variable "create_node_group" {
  description = "Whether to create the EKS node group in this apply"
  type        = bool
  default     = true
}


variable "route53_zone_id" {
  description = "Route53 hosted zone ID for sharonlinuxstudy.org"
  type        = string
  default     = "Z0234957230KHKPTLTYPV"
}


variable "api_gw_waf_acl_arn" {
  description = "WAFv2 Web ACL ARN to attach to API Gateway REST stage"
  type        = string
  default     = null
}

variable "api_waf_enabled" {
  description = "Whether to attach WAF to the API Gateway REST API"
  type        = bool
  default     = true
}

variable "api_waf_acl_name" {
  description = "Name of the WAFv2 Web ACL to attach to API Gateway"
  type        = string
  default     = "null"
}

variable "waf_name" {
  description = "Name of the WAFv2 Web ACL to create"
  type        = string
  default     = "null"
}


variable "cluster_name" {
  type        = string
  default     = null
  description = "Optional cluster name — used only if caller passes it in"
}

variable "enable_ingress_controller" {
  description = "Enable ingress controller installation"
  type        = bool
  default     = true
}



variable "enable_tgw_attachment" {
  description = "Enable TGW attachment and TGW-based routes in the spoke VPC"
  type        = bool
  default     = false
}

variable "enable_eks" {
  description = "Enable creation of the EKS cluster and node groups"
  type        = bool
  default     = false
}

variable "enable_apigw_vpclink" {
  description = "Enable API Gateway VPC Link to ingress NLB"
  type        = bool
  default     = false
}

variable "aws_api_gateway_vpc_link" {
  description = "Enable API Gateway VPC Link to ingress NLB"
  type        = bool
  default     = false
}


variable "cloudfront_acm_cert_arn" {
  type = string
 default ="arn:aws:acm:us-east-1:289880680686:certificate/b353a77b-23fd-4041-b363-987b23df61 6d"
}


variable "cf_acm_us_east_1_arn" {
  description = "ACM certificate ARN in us-east-1 for CloudFront (must cover the domain names you use)"
  type        = string
  default = "arn:aws:acm:us-east-1:289880680686:certificate/b353a77b-23fd-4041-b363-987b23df616d"
}










