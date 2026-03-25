# Create the TGW Route Table (the resource your errors say is missing)
resource "aws_ec2_transit_gateway_route_table" "this" {
  transit_gateway_id = var.transit_gateway_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-tgw-rt-${var.route_table_name}"
  })
}

# ---- Routes: iterate plan-known map keys directly ----
resource "aws_ec2_transit_gateway_route" "this" {
  for_each = var.routes

  destination_cidr_block         = each.value.destination_cidr
  transit_gateway_attachment_id  = each.value.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
}

# Build stable index-based maps from lists (keys are plan-known)
locals {
  _assoc_ids = coalesce(var.association_attachment_ids, [])
  _assoc_map = { for i in range(length(local._assoc_ids)) : tostring(i) => local._assoc_ids[i] }

  _prop_ids  = coalesce(var.propagation_attachment_ids, [])
  _prop_map  = { for i in range(length(local._prop_ids))  : tostring(i) => local._prop_ids[i] }
}

# ---- Associations ----
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = local._assoc_map

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id  = each.value
  replace_existing_association   = true
}

# ---- Propagations ----
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local._prop_map

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this.id
  transit_gateway_attachment_id  = each.value
}

