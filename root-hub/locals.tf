locals {
  # =========================
  # Environment & naming
  # =========================
  env         = var.environment != null ? var.environment : terraform.workspace
  name_prefix = var.name_prefix_override != null ? var.name_prefix_override : "jc-${local.env}"
  vpc_name    = "${local.name_prefix}-vpc"

  onprem_cidrs = var.onprem_cidrs

  # Convert list to map for VPN module
  onprem_cidrs_map = {
    for idx, cidr in var.onprem_cidrs : "onprem_${idx}" => cidr
  }

  tags = merge(
    var.tags,
    {
      Name        = local.vpc_name
      Application = var.application_name
      Owner       = var.owner
      Stack       = "hub"
      Environment = local.env
      ManagedBy   = "Terraform"
    }
  )

  # =========================
  # On-Prem Route Helper
  # =========================
  onprem_routes = [
    for cidr in var.onprem_cidrs : {
      destination        = cidr
      transit_gateway_id = module.hub_tgw.tgw_id
    }
  ]

  # =========================
  # Spoke CIDRs → TGW routes (Hub VPC side)
  # Includes all VPCs that Hub needs to reach via TGW
  # =========================
  spoke_tgw_routes = concat(
    [
      for cidr in var.spoke_supernet_cidrs : {
        destination        = cidr
        transit_gateway_id = module.hub_tgw.tgw_id
      }
    ],
    [
      {
        destination        = var.shared_cidr  # 10.62.0.0/16
        transit_gateway_id = module.hub_tgw.tgw_id
      },
      {
        destination        = var.build_cidr   # 10.63.0.0/16
        transit_gateway_id = module.hub_tgw.tgw_id
      }
    ]
  )

  # Firewall endpoint may not exist (module has count)
  firewall_endpoint_id = var.enable_firewall ? try(module.hub_firewall_endpoints[0].first_endpoint_id, null) : null

  # =========================
  # VPC Route Tables (HUB VPC)
  # =========================
  route_tables = {
    public = {
      routes = concat(
        [
          { destination = "0.0.0.0/0", gateway_id = module.hub_igw.igw_id }
        ],
        local.spoke_tgw_routes
      )
    }

    bastion = {
      routes = concat(
        var.enable_firewall ? [
          { destination = "0.0.0.0/0", vpc_endpoint_id = local.firewall_endpoint_id }
        ] : [],
        local.spoke_tgw_routes,
        local.onprem_routes
      )
    }

    vm = {
      routes = concat(
        var.enable_nat ? [
          { destination = "0.0.0.0/0", nat_gateway_id = module.hub_nat.nat_gateway_ids[0] }
        ] : [],
        local.spoke_tgw_routes,
        local.onprem_routes
      )
    }

    api = {
      routes = concat(
        var.enable_nat ? [
          { destination = "0.0.0.0/0", nat_gateway_id = module.hub_nat.nat_gateway_ids[0] }
        ] : [],
        local.spoke_tgw_routes,
        local.onprem_routes
      )
    }

    gateway = {
      routes = concat(
        local.spoke_tgw_routes,
        local.onprem_routes,
        var.enable_firewall ? [
          { destination = "0.0.0.0/0", vpc_endpoint_id = local.firewall_endpoint_id }
        ] : []
      )
    }

    firewall = {
      routes = concat(
        var.enable_nat ? [
          { destination = "0.0.0.0/0", nat_gateway_id = module.hub_nat.nat_gateway_ids[0] }
        ] : [],
        local.spoke_tgw_routes
      )
    }

    vpn = {
      routes = local.onprem_routes
    }
  }

  # Subnet ↔ RT associations
  associations = {
    public_subnet = { subnet_key = "public_subnet", rt_key = "public" }
    bastion       = { subnet_key = "bastion",       rt_key = "bastion" }
    vm            = { subnet_key = "vm",            rt_key = "vm" }
    api           = { subnet_key = "api",           rt_key = "api" }
    gateway       = { subnet_key = "gateway",       rt_key = "gateway" }
    firewall      = { subnet_key = "firewall",      rt_key = "firewall" }
    vpn           = { subnet_key = "vpn",           rt_key = "vpn" }
    public_subnet1 = { subnet_key = "public_subnet1", rt_key = "public" }
    public_subnet2 = { subnet_key = "public_subnet2", rt_key = "public" }  # NEW

  }

  # =========================
  # TGW helpers & RT definitions
  # =========================

  hub_tgw_attachment_id = try(module.hub_tgw_attachment.attachment_id, null)

  # ========================================
  # TGW SPOKE RT: Routes for Dev/QA/Prod
  # ========================================
  # Only default route and hub routes - cross-VPC routes added by each spoke/shared/build module
  tgw_spoke_routes = merge(
    {
      default_to_hub = {
        destination_cidr = "0.0.0.0/0"
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
      hub_vpc = {
        destination_cidr = var.vpc_cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    },
    {
      for idx, cidr in var.onprem_cidrs : "onprem_${idx}" => {
        destination_cidr = cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    }
  )

  # ========================================
  # TGW SHARED RT: Routes for Shared VPC
  # ========================================
  # Only default route and hub routes - cross-VPC routes added by spoke/build modules
  tgw_shared_routes = merge(
    {
      default_to_hub = {
        destination_cidr = "0.0.0.0/0"
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
      hub_vpc = {
        destination_cidr = var.vpc_cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    },
    {
      for idx, cidr in var.onprem_cidrs : "onprem_${idx}" => {
        destination_cidr = cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    }
  )

  # ========================================
  # TGW BUILD RT: Routes for Build VPC
  # ========================================
  # Only default route and hub routes - cross-VPC routes added by spoke/shared modules
  tgw_build_routes = merge(
    {
      default_to_hub = {
        destination_cidr = "0.0.0.0/0"
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
      hub_vpc = {
        destination_cidr = var.vpc_cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    },
    {
      for idx, cidr in var.onprem_cidrs : "onprem_${idx}" => {
        destination_cidr = cidr
        attachment_id    = module.hub_tgw_attachment.attachment_id
      }
    }
  )

  # ========================================
  # TGW HUB RT: Routes for Hub/VPN
  # ========================================
  # Hub learns spoke/shared/build via propagation from each attachment
  tgw_hub_routes = {
    for idx, cidr in var.onprem_cidrs : "onprem_${idx}" => {
      destination_cidr = cidr
      attachment_id    = module.hub_site_to_site_vpn.tgw_attachment_id
    }
  }

  # =========================
  # VPN naming
  # =========================
  vpn_customer_gateway_name = "${local.name_prefix}-cgw"
  vpn_connection_name       = "${local.name_prefix}-vpn"

  wildcard_cert_arn = "arn:aws:acm:us-west-2:289880680686:certificate/101ccb5b-a014-46e7-96e7-e88127cbf894"

}
