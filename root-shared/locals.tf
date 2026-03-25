locals {
  # -------------------------
  # Environment & naming
  # -------------------------
  env         = var.environment != null ? var.environment : terraform.workspace
  name_prefix = var.name_prefix_override != null ? var.name_prefix_override : "jc-${local.env}"
  vpc_name    = "${local.name_prefix}-shared-vpc"

  # -------------------------
  # Tags
  # -------------------------
  tags = merge(
    var.tags,
    {
      Name        = local.vpc_name
      Application = var.application_name
      Owner       = var.owner
      Stack       = "shared"
      Environment = local.env
      ManagedBy   = "Terraform"
    }
  )

  # -------------------------
  # CIDRs to reach via TGW
  # -------------------------
  # Spoke VPC CIDRs (dev/qa/prod)
  spoke_vpc_cidrs = [
    "10.59.0.0/16", # dev
    "10.60.0.0/16", # qa
    "10.61.0.0/16", # prod
  ]

  # Build VPC CIDR
  build_vpc_cidr = "10.63.0.0/16"

  # Hub VPC CIDR
  hub_vpc_cidr = "10.58.0.0/16"

  # All destinations Shared must reach
  shared_tgw_dest_cidrs = concat(
    local.spoke_vpc_cidrs,
    [local.build_vpc_cidr],
    [local.hub_vpc_cidr]
  )

  # -------------------------
  # TGW Routes for Shared VPC
  # -------------------------
  shared_tgw_routes = concat(
    [
      {
        destination        = "0.0.0.0/0"
        transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
      }
    ],
    [
      for cidr in local.shared_tgw_dest_cidrs : {
        destination        = cidr
        transit_gateway_id = data.terraform_remote_state.hub.outputs.tgw_id
      }
    ]
  )

  # -------------------------
  # VPC Route Tables (Shared VPC)
  # -------------------------
  route_tables = {
    vault = {
      routes = local.shared_tgw_routes
    }

    sonar = {
      routes = local.shared_tgw_routes
    }
  }

  # -------------------------
  # Subnet ↔ Route Table associations
  # -------------------------
  associations = {
    vault_a = { subnet_key = "vault_a", rt_key = "vault" }
    vault_b = { subnet_key = "vault_b", rt_key = "vault" }

    sonar_a = { subnet_key = "sonar_a", rt_key = "sonar" }
    sonar_b = { subnet_key = "sonar_b", rt_key = "sonar" }
  }

}