locals {
  nat_count = var.enable_nat ? (var.single_nat_gateway ? 1 : length(var.public_subnet_ids)) : 0
}

resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[var.single_nat_gateway ? 0 : count.index]
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat-${count.index}" })
}

