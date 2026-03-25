locals {
  private_route_tables = {
    for idx, rt_id in var.private_route_table_ids :
    idx => rt_id
  }
}




resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    {
      Name = "nat-eip"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = merge(
    {
      Name = "nat-gateway"
    },
    var.tags
  )

  depends_on = [aws_eip.nat]
}

# Add default route via NAT to each private RT

resource "aws_route" "private_default" {
  for_each = local.private_route_tables

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

