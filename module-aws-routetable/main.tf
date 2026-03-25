#############################################
# module-aws-routetable/main.tf  (UPDATED)
#############################################

# 1) Create one route table per entry
resource "aws_route_table" "this" {
  for_each = var.route_tables
  vpc_id   = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-rt"
  })
}

# 2) Create routes with STABLE keys (rt_name + destination + target)
#    This prevents route replacement when list order changes.
resource "aws_route" "this" {
  for_each = {
    for route in flatten([
      for rt_key, rt in var.route_tables : [
        for r in rt.routes : {
          rt_key                    = rt_key
          destination               = r.destination
          gateway_id                = try(r.gateway_id, null)
          nat_gateway_id            = try(r.nat_gateway_id, null)
          transit_gateway_id        = try(r.transit_gateway_id, null)
          vpc_endpoint_id           = try(r.vpc_endpoint_id, null)
          vpc_peering_connection_id = try(r.vpc_peering_connection_id, null)
          egress_only_gateway_id    = try(r.egress_only_gateway_id, null)
          network_interface_id      = try(r.network_interface_id, null)
          local_gateway_id          = try(r.local_gateway_id, null)
          carrier_gateway_id        = try(r.carrier_gateway_id, null)
          core_network_arn          = try(r.core_network_arn, null)

          # Stable unique key per route
          # (destination + target so we don't collide if you ever have same destination w/ different target)
          key = join("__", compact([
            rt_key,
            replace(r.destination, "/", "_"),
            try(r.transit_gateway_id, null) != null ? "tgw-${r.transit_gateway_id}" : null,
            try(r.nat_gateway_id, null)     != null ? "nat-${r.nat_gateway_id}" : null,
            try(r.gateway_id, null)         != null ? "igw-${r.gateway_id}" : null,
            try(r.vpc_endpoint_id, null)    != null ? "vpce-${r.vpc_endpoint_id}" : null,
            try(r.vpc_peering_connection_id, null) != null ? "pcx-${r.vpc_peering_connection_id}" : null,
            try(r.network_interface_id, null) != null ? "eni-${r.network_interface_id}" : null,
            try(r.local_gateway_id, null) != null ? "lgw-${r.local_gateway_id}" : null,
            try(r.carrier_gateway_id, null) != null ? "cgw-${r.carrier_gateway_id}" : null,
            try(r.core_network_arn, null) != null ? "core-${replace(r.core_network_arn, ":", "_")}" : null,
          ]))
        }
      ]
    ]) : route.key => route
  }

  route_table_id         = aws_route_table.this[each.value.rt_key].id
  destination_cidr_block = each.value.destination

  # Route targets
  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  transit_gateway_id        = each.value.transit_gateway_id
  vpc_endpoint_id           = each.value.vpc_endpoint_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  egress_only_gateway_id    = each.value.egress_only_gateway_id
  network_interface_id      = each.value.network_interface_id
  local_gateway_id          = each.value.local_gateway_id
  carrier_gateway_id        = each.value.carrier_gateway_id
  core_network_arn          = each.value.core_network_arn

  # Only create routes that have at least one target defined
  lifecycle {
    precondition {
      condition = (
        each.value.gateway_id != null ||
        each.value.nat_gateway_id != null ||
        each.value.transit_gateway_id != null ||
        each.value.vpc_endpoint_id != null ||
        each.value.vpc_peering_connection_id != null ||
        each.value.egress_only_gateway_id != null ||
        each.value.network_interface_id != null ||
        each.value.local_gateway_id != null ||
        each.value.carrier_gateway_id != null ||
        each.value.core_network_arn != null
      )
      error_message = "At least one route target must be specified for route ${each.key}"
    }
  }
}

# 3) Associate subnets to their route tables
resource "aws_route_table_association" "this" {
  for_each = var.associations

  subnet_id      = var.subnet_ids[each.value.subnet_key]
  route_table_id = aws_route_table.this[each.value.rt_key].id
}
