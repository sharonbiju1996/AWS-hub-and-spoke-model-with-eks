# -----------------------------
# VPC
# -----------------------------
module "shared_vpc" {
  source   = "../module-aws-vpc"
  vpc_name = local.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

# -----------------------------
# Subnets
# -----------------------------
module "shared_subnets" {
  source      = "../module-aws-subnets"
  vpc_id      = module.shared_vpc.vpc_id
  az_count    = var.az_count
  name_prefix = local.name_prefix
  tags        = local.tags
  subnets     = var.subnets
}

# -----------------------------
# TGW Attachment
# -----------------------------
module "shared_tgw_attachment" {
  source = "../module-aws-tgw-attachment"

  transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
  vpc_id             = module.shared_vpc.vpc_id

  # Use TWO subnets in different AZs for HA
  subnet_ids = [
    module.shared_subnets.subnet_ids_by_key["vault_a"],
    module.shared_subnets.subnet_ids_by_key["vault_b"],
  ]

  name_prefix = local.name_prefix
  tags        = local.tags

  appliance_mode_support          = var.shared_appliance_mode_support
  default_route_table_association = false
  default_route_table_propagation = false
}

# -----------------------------
# TGW Binding to SHARED RT
# -----------------------------




module "shared_tgw_binding" {
  source = "../module-aws-tgw-spoke"

  attachment_id        = module.shared_tgw_attachment.attachment_id
  hub_route_table_id   = data.terraform_remote_state.hub.outputs.tgw_rt_hub_id
  spoke_route_table_id = data.terraform_remote_state.hub.outputs.tgw_rt_shared_id

  # Add route TO shared VPC in other route tables
  vpc_cidr = var.vpc_cidr

  add_route_to_route_tables = {
    spoke = data.terraform_remote_state.hub.outputs.tgw_rt_spoke_id
    build = data.terraform_remote_state.hub.outputs.tgw_rt_build_id
  }

  tags = local.tags

  depends_on = [module.shared_tgw_attachment]
}

# -----------------------------
# Route Tables
# -----------------------------
module "shared_rt" {
  source      = "../module-aws-routetable"
  vpc_id      = module.shared_vpc.vpc_id
  name_prefix = local.name_prefix
  tags        = local.tags

  subnet_ids   = module.shared_subnets.subnet_ids_by_key
  route_tables = local.route_tables
  associations = local.associations

  depends_on = [
    module.shared_tgw_attachment,
    module.shared_tgw_binding
  ]
}


module "vault" {
  source = "../module-aws-vault"
  count  = var.enable_vault ? 1 : 0

  name_prefix = local.name_prefix
  vpc_id      = module.shared_vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
  aws_region  = var.aws_region

  subnet_ids = [
    module.shared_subnets.subnet_ids_by_key["vault_a"],
    module.shared_subnets.subnet_ids_by_key["vault_b"]
  ]

  instance_type = var.vault_instance_type
  cluster_size  = var.vault_cluster_size
  volume_size   = 20

  allowed_cidrs = [
    "10.58.0.0/16",  # Hub
    "10.59.0.0/16",  # Spoke dev
    "10.60.0.0/16",  # Spoke uat
    "10.61.0.0/16",  # Spoke prod
    "10.62.0.0/16",  # Shared
    "10.63.0.0/16"   # Build
  ]

  ssh_cidrs = ["10.58.0.0/16"]

  # SSM Session Manager
  enable_ssm = true

  # DNS
  create_dns_zone = true
  dns_zone_name   = "shared.internal"
  dns_record_name = "vault"

  tags = local.tags
}


# ========================================
# SonarQube
# ========================================




module "sonarqube" {
  source = "../module-aws-sonarqube"
  count  = var.enable_sonarqube ? 1 : 0

  name_prefix = local.name_prefix
  vpc_id      = module.shared_vpc.vpc_id
  subnet_id   = module.shared_subnets.subnet_ids_by_key["sonar_a"]

  instance_type = var.sonarqube_instance_type
  volume_size   = var.sonarqube_volume_size
  enable_ssm    = true

  

  allowed_cidrs = [
    "10.58.0.0/16",
    "10.59.0.0/16",
    "10.60.0.0/16",
    "10.61.0.0/16",
    "10.62.0.0/16",
    "10.63.0.0/16"
  ]

  ssh_cidrs = ["10.58.0.0/16"]

  tags = local.tags
}