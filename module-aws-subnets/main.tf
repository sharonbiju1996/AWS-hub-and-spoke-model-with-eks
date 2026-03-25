data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}




# In your subnet module (where you have the aws_subnet resource)

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = local.azs[each.value.az_index]
  map_public_ip_on_launch = each.value.type == "public"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-subnet-${each.key}"
      type = each.value.type
    },
    # Add EKS tags conditionally based on subnet key
    contains(["eks", "eks1"], each.key) ? {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    } : {}
  )
}