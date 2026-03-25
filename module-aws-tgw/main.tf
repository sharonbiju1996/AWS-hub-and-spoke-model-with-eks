########################################
# Transit Gateway
########################################

resource "aws_ec2_transit_gateway" "this" {
  description                     = "${var.name_prefix}-tgw"
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw"
    }
  )
}

########################################
# Optional TGW Route Table
# (Creates a dedicated TGW route table if needed)
########################################

resource "aws_ec2_transit_gateway_route_table" "this" {
  count               = var.create_tgw_rt ? 1 : 0
  transit_gateway_id  = aws_ec2_transit_gateway.this.id
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tgw-rt"
    }
  )
}

