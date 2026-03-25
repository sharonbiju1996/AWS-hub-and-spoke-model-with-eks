resource "aws_ec2_transit_gateway_route_table_association" "spoke_assoc" {
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = var.spoke_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_hub" {
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = var.hub_route_table_id
}

# Add route TO this VPC in other route tables
resource "aws_ec2_transit_gateway_route" "to_this_vpc" {
  for_each = var.vpc_cidr != "" ? var.add_route_to_route_tables : {}

  transit_gateway_route_table_id = each.value
  destination_cidr_block         = var.vpc_cidr
  transit_gateway_attachment_id  = var.attachment_id
}
