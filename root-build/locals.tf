locals {
  # -------------------------
  # Environment & naming
  # -------------------------
  env         = var.environment != null ? var.environment : terraform.workspace
  name_prefix = var.name_prefix_override != null ? var.name_prefix_override : "jc-${local.env}"
  vpc_name    = "${local.name_prefix}-vpc"

  # -------------------------
  # Tags
  # -------------------------
  tags = merge(
    var.tags,
    {
      Name        = local.vpc_name
      Application = var.application_name
      Owner       = var.owner
      Stack       = "build"
      Environment = local.env
      ManagedBy   = "Terraform"
    }
  )

  # -------------------------
  # CIDRs to reach via TGW
  # -------------------------
  build_tgw_dest_cidrs = concat(
    var.spoke_vpc_cidrs,
    [var.shared_vpc_cidr],
    [var.hub_vpc_cidr]
  )

  # -------------------------
  # TGW Routes for Build VPC subnets
  # -------------------------
  build_tgw_routes = concat(
    [
      {
        destination        = "0.0.0.0/0"
        transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
      }
    ],
    [
      for cidr in local.build_tgw_dest_cidrs : {
        destination        = cidr
        transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
      }
    ]
  )

  # -------------------------
  # VPC Route Tables (Build VPC)
  # -------------------------
  route_tables = {
    build = {
      routes = local.build_tgw_routes
    }
    agent = {
      routes = local.build_tgw_routes
    }
  }

  # -------------------------
  # Subnet ↔ Route Table associations
  # -------------------------
  associations = {
    build_a = { subnet_key = "build_a", rt_key = "build" }
    build_b = { subnet_key = "build_b", rt_key = "build" }
    agent_a = { subnet_key = "agent_a", rt_key = "agent" }
    agent_b = { subnet_key = "agent_b", rt_key = "agent" }
  }
}
