output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.subnet.public_subnet_ids
}

output "private_subnets" {
  value = module.subnet.private_subnet_ids
}

output "nat_gateway_id" {
  value = module.nat.nat_gateway_id
}

output "azdo_agents_asg_name" {
  value = module.azdo_agents.asg_name
}

output "azdo_agents_security_group_id" {
  value = module.azdo_agents.security_group_id
}
