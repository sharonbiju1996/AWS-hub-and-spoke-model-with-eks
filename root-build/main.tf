# ========================================
# Build VPC
# ========================================
module "build_vpc" {
  source   = "../module-aws-vpc"
  vpc_name = local.vpc_name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

# ========================================
# Build Subnets
# ========================================
module "build_subnets" {
  source      = "../module-aws-subnets"
  vpc_id      = module.build_vpc.vpc_id
  az_count    = var.az_count
  name_prefix = local.name_prefix
  tags        = local.tags
  subnets     = var.subnets
}

# ========================================
# TGW Attachment
# ========================================
module "build_tgw_attachment" {
  source = "../module-aws-tgw-attachment"

  transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
  vpc_id             = module.build_vpc.vpc_id
  subnet_ids = [
    module.build_subnets.subnet_ids_by_key["build_a"],
    module.build_subnets.subnet_ids_by_key["build_b"],
  ]
  name_prefix                     = local.name_prefix
  tags                            = local.tags
  appliance_mode_support          = false
  default_route_table_association = false
  default_route_table_propagation = false
}

# ========================================
# TGW Binding (Association + Propagation + Cross-VPC Routes)
# ========================================
module "build_tgw_binding" {
  source = "../module-aws-tgw-spoke"

  attachment_id        = module.build_tgw_attachment.attachment_id
  hub_route_table_id   = data.terraform_remote_state.hub.outputs.tgw_rt_hub_id
  spoke_route_table_id = data.terraform_remote_state.hub.outputs.tgw_rt_build_id

  # Add route TO build VPC in other route tables
  vpc_cidr = var.vpc_cidr  # 10.63.0.0/16

  add_route_to_route_tables = {
    spoke  = data.terraform_remote_state.hub.outputs.tgw_rt_spoke_id
    shared = data.terraform_remote_state.hub.outputs.tgw_rt_shared_id
  }

  tags = local.tags

  depends_on = [module.build_tgw_attachment]
}

# ========================================
# Route Tables
# ========================================
module "build_rt" {
  source       = "../module-aws-routetable"
  vpc_id       = module.build_vpc.vpc_id
  name_prefix  = local.name_prefix
  tags         = local.tags
  subnet_ids   = module.build_subnets.subnet_ids_by_key
  route_tables = local.route_tables
  associations = local.associations

  depends_on = [
    module.build_tgw_attachment,
    module.build_tgw_binding
  ]
}


# root-shared/main.tf or root-build/main.tf




module "azdo_agent" {
  source = "../module-aws-azdo-agent"
  count  = var.enable_azdo_agent ? 1 : 0

  name_prefix = local.name_prefix
  vpc_id      = module.build_vpc.vpc_id
  aws_region  = var.aws_region

  subnet_ids = [
    module.build_subnets.subnet_ids_by_key["build_a"],
    module.build_subnets.subnet_ids_by_key["build_b"]
  ]

  ami_id        = var.azdo_agent_ami_id
  instance_type = var.azdo_agent_instance_type
  volume_size   = 50

  # ASG Settings
  desired_capacity = var.azdo_agent_desired_capacity
  min_size         = var.azdo_agent_min_size
  max_size         = var.azdo_agent_max_size

  # Security
  ssh_cidrs = ["10.58.0.0/16"]

  # Secrets Manager
  secret_name = "azdo/agent/config"

  # Optional Features
  enable_ssm              = true
  enable_ecr_access       = true
  enable_scaling_policies = false

  tags = local.tags
}