locals {
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    idx => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }

  common_tags = var.tags
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "public-${each.value.az}"
      Tier = "public"
    }
  )
}

# Private subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name = "private-${each.value.az}"
      Tier = "private"
    }
  )
}

# Public route table with IGW route
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "public-rt"
    }
  )
}

# Associate public subnets with public RT
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables (one per private subnet).
# NAT routes will be added by the NAT module.
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "private-rt-${each.value.availability_zone}"
      Tier = "private"
    }
  )
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}
