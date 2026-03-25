resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  dns_support            = "enable"
  ipv6_support           = "disable"
  appliance_mode_support = var.appliance_mode_support ? "enable" : "disable"

  # do NOT hardcode "enable"/"disable" here—use the bool vars from variables.tf
  transit_gateway_default_route_table_association = var.default_route_table_association
  transit_gateway_default_route_table_propagation = var.default_route_table_propagation

  tags = merge(var.tags, { Name = "${var.name_prefix}-tgw-attachment" })

  lifecycle {
    ignore_changes = [
      transit_gateway_default_route_table_association,
      transit_gateway_default_route_table_propagation,
    ]
  }
}
