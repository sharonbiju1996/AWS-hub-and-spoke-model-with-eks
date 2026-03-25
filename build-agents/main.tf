# -------------------
# VPC
# -------------------

  module "vpc" {
  source = "./aws-vpc"

  cidr_block = var.vpc_cidr
  name       = local.vpc_name
  tags       = local.tags
}


  

# -------------------
# Internet Gateway
# -------------------
module "igw" {
  source = "./aws-igw"

  vpc_id = module.vpc.vpc_id

  tags = local.tags
}

# -------------------
# Subnets (public + private)
# -------------------
module "subnet" {
  source = "./aws-subnet"

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  igw_id               = module.igw.igw_id

  tags = local.tags
}

# -------------------
# NAT Gateway (for private subnets)
# -------------------
module "nat" {
  source = "./aws-nat"

  vpc_id                 = module.vpc.vpc_id
  public_subnet_id       = module.subnet.public_subnet_ids[0]
  private_route_table_ids = module.subnet.private_route_table_ids

  tags = local.tags
}

# -------------------
# Azure DevOps Self-hosted Agents (ASG)
# -------------------
module "azdo_agents" {
  source = "./aws-azdo-agents"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnet.private_subnet_ids
  name_prefix = local.name_prefix

 
  instance_type = var.agent_instance_type

  desired_capacity = var.agent_desired_capacity
  min_size         = var.agent_min_size
  max_size         = var.agent_max_size
  

  azure_devops_org_url   = var.azure_devops_org_url
  azure_devops_pool_name = var.azure_devops_pool_name
  azure_devops_pat       = var.azure_devops_pat

 
  agent_name_prefix = "azdo-agent"

  tags = local.tags
}