# root-hub/main.tf

# -----------------------------
# VPC
# -----------------------------
module "hub_vpc" {
  source   = "../module-aws-vpc"
  vpc_name = "jc-${local.env}-vpc" # or use local.vpc_name if you prefer
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

# -----------------------------
# Subnets
# -----------------------------
module "hub_subnets" {
  source      = "../module-aws-subnets"
  vpc_id      = module.hub_vpc.vpc_id
  az_count    = var.az_count
  name_prefix = local.name_prefix # was var.name_prefix
  tags        = local.tags
  subnets     = var.subnets
}

# -----------------------------
# Internet Gateway
# -----------------------------
module "hub_igw" {
  source = "../module-aws-igw"
  vpc_id = module.hub_vpc.vpc_id
  name   = "${local.name_prefix}-igw" # e.g., jc-hub-igw
  tags   = local.tags
}

# -----------------------------
# NAT (single or per-AZ)
# -----------------------------
module "hub_nat" {
  source             = "../module-aws-nat"
  name_prefix        = local.name_prefix # was var.name_prefix
  public_subnet_ids  = module.hub_subnets.public_subnet_ids
  enable_nat         = var.enable_nat
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

# -----------------------------
# Route tables (built from locals)
# -----------------------------
module "hub_rt" {
  source      = "../module-aws-routetable"
  vpc_id      = module.hub_vpc.vpc_id
  name_prefix = local.name_prefix # was var.name_prefix
  tags        = local.tags

  subnet_ids   = module.hub_subnets.subnet_ids_by_key
  route_tables = local.route_tables
  associations = local.associations
  depends_on = [
    module.hub_nat,
    module.hub_tgw,
    module.hub_firewall_endpoints,
    module.hub_igw,
    module.hub_tgw_attachment
  ]
}

# ---------------------------------------------------
# Transit Gateway (Core network)
# ---------------------------------------------------


module "hub_tgw" {
  source      = "../module-aws-tgw"
  name_prefix = local.name_prefix
  tags        = local.tags

  amazon_side_asn                 = var.tgw_amazon_side_asn
  auto_accept_shared_attachments  = var.tgw_auto_accept_shared_attachments
  default_route_table_association = var.tgw_default_route_table_association
  default_route_table_propagation = var.tgw_default_route_table_propagation
  dns_support                     = var.tgw_dns_support
  vpn_ecmp_support                = var.tgw_vpn_ecmp_support

}
# -----------------------------
# Network Firewall Endpoints
# -----------------------------
module "hub_firewall_endpoints" {
  count  = var.enable_firewall ? 1 : 0
  source = "../module-aws-firewall-endpoints"

  vpc_id              = module.hub_vpc.vpc_id
  name_prefix         = local.name_prefix
  firewall_subnet_ids = module.hub_subnets.firewall_subnet_ids
  az_count            = var.az_count
  tags                = local.tags

  policy_stateless_default_actions          = var.firewall_policy_stateless_default_actions
  policy_stateless_fragment_default_actions = var.firewall_policy_stateless_fragment_default_actions
  rule_capacity                             = var.firewall_rule_capacity
}

# ---------------------------------------------------
# Transit Gateway VPC Attachment
# ---------------------------------------------------


module "hub_tgw_attachment" {
  source = "../module-aws-tgw-attachment"

  transit_gateway_id = module.hub_tgw.tgw_id
  vpc_id             = module.hub_vpc.vpc_id
  subnet_ids = [
    module.hub_subnets.subnet_ids_by_key["gateway"]
  ]
  name_prefix = local.name_prefix
  tags        = local.tags

  # Use variables for flexibility
  appliance_mode_support          = var.hub_appliance_mode_support
  default_route_table_association = var.hub_tgw_route_table_association
  default_route_table_propagation = var.hub_tgw_route_table_propagation
}




# ========================================
# TGW Route Table: Hub
# ========================================



# Hub TGW RT (hub learns spokes)


module "hub_tgw_rt_hub" {
  source                     = "../module-aws-tgw-route-table"
  transit_gateway_id         = module.hub_tgw.tgw_id
  route_table_name           = "hub"
  name_prefix                = local.name_prefix
  tags                       = local.tags


  association_attachment_ids = [
    module.hub_tgw_attachment.attachment_id,        # HUB VPC
    module.hub_site_to_site_vpn.tgw_attachment_id   # (optional) VPN attachment
  ]

  # Only VPN propagates here; spokes will add themselves
  propagation_attachment_ids = [
    module.hub_site_to_site_vpn.tgw_attachment_id
  ]
  
  routes                     = local.tgw_hub_routes

  #  ENSURE VPN ATTACHMENT EXISTS BEFORE ROUTE TABLE ASSOCIATION
  depends_on = [
    module.hub_tgw_attachment,          # Hub VPC TGW attachment
    module.hub_site_to_site_vpn         # VPN and its TGW attachment
  ]
}





# ========================================
# TGW Route Table: Spoke
# ========================================


# Spoke TGW RT (spokes use this; send to hub)


module "hub_tgw_rt_spoke" {
  source             = "../module-aws-tgw-route-table"
  transit_gateway_id = module.hub_tgw.tgw_id
  route_table_name   = "spoke"
  name_prefix        = local.name_prefix
  tags               = local.tags



    # Spokes will associate themselves; hub doesn’t manage their list
  association_attachment_ids = []

  # Optional: keep propagation from hub/VPN if your module uses this;
  # but often you can rely just on static routes in local.tgw_spoke_routes
  propagation_attachment_ids = []



  routes = local.tgw_spoke_routes

  # Make sure attachments exist before associations/propagations
  depends_on = [
    module.hub_tgw_attachment,
    module.hub_site_to_site_vpn
  ]
}


module "hub_tgw_rt_shared" {
  source             = "../module-aws-tgw-route-table"
  transit_gateway_id = module.hub_tgw.tgw_id
  route_table_name   = "shared"
  name_prefix        = local.name_prefix
  tags               = local.tags

  association_attachment_ids = []       # shared stack will associate itself
  propagation_attachment_ids = []       # optional

  routes = local.tgw_shared_routes

  depends_on = [
    module.hub_tgw_attachment,
    module.hub_site_to_site_vpn
  ]
}


# ========================================
# TGW Route Table: Build
# ========================================
module "hub_tgw_rt_build" {
  source             = "../module-aws-tgw-route-table"
  transit_gateway_id = module.hub_tgw.tgw_id
  route_table_name   = "build"
  name_prefix        = local.name_prefix
  tags               = local.tags

  association_attachment_ids = []  # build stack will associate itself
  propagation_attachment_ids = []

  routes = local.tgw_build_routes

  depends_on = [
    module.hub_tgw_attachment,
    module.hub_site_to_site_vpn
  ]
}


module "hub_site_to_site_vpn" {
  source = "../module-aws-site2site-vpn"

  # Customer Gateway (on-prem)
  customer_gateway_name = local.vpn_customer_gateway_name
  customer_gateway_ip   = var.customer_gateway_ip
  bgp_asn               = var.customer_gateway_bgp_asn

  # Termination on TGW or VGW – values come from variables
  use_transit_gateway = var.use_transit_gateway
  transit_gateway_id  = module.hub_tgw.tgw_id
  vpc_id              = var.vpn_vpc_id
  vpn_gateway_name    = var.vpn_gateway_name

  # VPN connection naming and behavior
  vpn_connection_name = local.vpn_connection_name
  static_routes_only  = var.vpn_static_routes_only

  # Static routes for on-prem – fully variable-driven
  
  
  static_routes     = local.onprem_cidrs_map

  # Tunnel config from variables (or empty string which module treats as auto)
  tunnel1_inside_cidr   = var.tunnel1_inside_cidr
  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_inside_cidr   = var.tunnel2_inside_cidr
  tunnel2_preshared_key = var.tunnel2_preshared_key

  tags = local.tags
}


# ========================================
# Monitoring Stack (root-hub/monitoring.tf)
# Add this file to your existing root-hub directory
# ========================================

module "monitoring" {
  source = "../module-aws-monitoring"
  count  = var.enable_monitoring ? 1 : 0

  name_prefix = local.name_prefix
  vpc_id      = module.hub_vpc.vpc_id
  subnet_id   = module.hub_subnets.subnet_ids_by_key["vm"]

  # EC2 Settings
  instance_type      = var.monitoring_instance_type
  volume_size        = var.monitoring_volume_size
  create_data_volume = var.monitoring_create_data_volume
  data_volume_size   = var.monitoring_data_volume_size
  enable_ssm         = true

  

  # Security
  allowed_cidrs = [
    "10.58.0.0/16",  # Hub
    "10.59.0.0/16",  # Spoke dev
    "10.60.0.0/16",  # Spoke uat
    "10.61.0.0/16",  # Spoke prod
    "10.62.0.0/16",  # Shared
    "10.63.0.0/16"   # Build
  ]

  ssh_cidrs = ["10.58.0.0/16"]  # Hub only

  tags = local.tags

  depends_on = [module.hub_vpc, module.hub_subnets]
}

#

# root-hub/main.tf




# root-hub/main.tf

########################################
# VPC Endpoints
########################################


# root-hub/main.tf

########################################
# VPC Endpoints
########################################
module "vpc_endpoints" {
  source = "../module-aws-endpoints"

  enable_apigw_endpoint = true
  vpc_id                = module.hub_vpc.vpc_id
  private_subnet_ids    = [
    module.hub_subnets.subnet_ids_by_key["api"]  # Use your private subnet key
  ]
  aws_region            = var.aws_region
  allowed_cidr_blocks   = ["10.58.0.0/16"]

  tags = local.tags
}

########################################
# ALB
########################################








module "alb" {
  source = "../module-aws-alb"

  vpc_id            = module.hub_vpc.vpc_id
  public_subnet_ids = [
    module.hub_subnets.subnet_ids_by_key["public_subnet1"],
    module.hub_subnets.subnet_ids_by_key["public_subnet2"]
  ]
  certificate_arn            = local.wildcard_cert_arn
  vpce_network_interface_ids = module.vpc_endpoints.apigw_vpce_network_interface_ids
  
  # Private API Gateway invoke host for transform rules
  private_apigw_invoke_host = "${module.api_gateway_hub.rest_api_id}-${module.vpc_endpoints.apigw_vpce_id}.execute-api.${var.aws_region}.amazonaws.com"
  root_domain               = "idukkiflavours.shop"
  
  waf_enabled = false
  waf_acl_arn = ""

  tags = local.tags

  depends_on = [module.vpc_endpoints, module.api_gateway_hub]
}


module "api_gateway_hub" {
  source = "../module-aws-api-gateway-hub"

  vpc_endpoint_id = module.vpc_endpoints.apigw_vpce_id

  tags = local.tags

  depends_on = [module.vpc_endpoints]
}