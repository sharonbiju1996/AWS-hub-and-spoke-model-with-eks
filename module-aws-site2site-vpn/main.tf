locals {
  cgw_tags = merge(var.tags, {
    Name = var.customer_gateway_name
    Role = "CustomerGateway"
  })

  vgw_tags = merge(var.tags, {
    Name = var.vpn_gateway_name
    Role = "VPNGateway"
  })

  vpn_tags = merge(var.tags, {
    Name = var.vpn_connection_name
    Role = "SiteToSiteVPN"
  })
}

# 1) Customer Gateway (on-prem endpoint)
resource "aws_customer_gateway" "this" {
  bgp_asn    = var.bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = local.cgw_tags
}

# 2) (Optional) VPN Gateway (VGW), only when NOT using TGW
resource "aws_vpn_gateway" "this" {
  count = var.use_transit_gateway ? 0 : 1

  vpc_id = var.vpc_id
  tags   = local.vgw_tags
}

# 3) VPN Connection (TGW or VGW)
resource "aws_vpn_connection" "this" {
  customer_gateway_id = aws_customer_gateway.this.id
  type                = "ipsec.1"

  # Termination side in AWS:
  transit_gateway_id = var.use_transit_gateway ? var.transit_gateway_id : null
  vpn_gateway_id     = var.use_transit_gateway ? null : aws_vpn_gateway.this[0].id

  static_routes_only = var.static_routes_only

  # Tunnel config: non-empty string means override, empty means let AWS generate
  tunnel1_inside_cidr   = var.tunnel1_inside_cidr   != "" ? var.tunnel1_inside_cidr   : null
  tunnel2_inside_cidr   = var.tunnel2_inside_cidr   != "" ? var.tunnel2_inside_cidr   : null
  tunnel1_preshared_key = var.tunnel1_preshared_key != "" ? var.tunnel1_preshared_key : null
  tunnel2_preshared_key = var.tunnel2_preshared_key != "" ? var.tunnel2_preshared_key : null

  tags = local.vpn_tags
}


# Tag the Transit Gateway VPN attachment itself (so Name shows in TGW attachments)
resource "aws_ec2_tag" "tgw_vpn_attachment_name" {
  count = var.use_transit_gateway ? 1 : 0

  resource_id = aws_vpn_connection.this.transit_gateway_attachment_id
  key         = "Name"
  value       = var.vpn_connection_name
}


# 4) VPN static routes (on-prem networks)



# In your root module

