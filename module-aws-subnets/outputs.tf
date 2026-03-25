# module-aws-subnets/outputs.tf

output "subnet_ids_by_key" {
  description = "Map of subnet keys to subnet IDs (bastion, vm, vpn, api, gateway, firewall, public_subnet)"
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    for k, v in aws_subnet.this : v.id
    if var.subnets[k].type == "public"
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    for k, v in aws_subnet.this : v.id
    if var.subnets[k].type == "private"
  ]
}

output "vpn_subnet_ids" {
  description = "List of VPN subnet IDs"
  value = [
    for k, v in aws_subnet.this : v.id
    if var.subnets[k].type == "vpn"
  ]
}

output "firewall_subnet_ids" {
  description = "List of firewall subnet IDs"
  value = [
    for k, v in aws_subnet.this : v.id
    if var.subnets[k].type == "firewall"
  ]
}

output "all_subnet_ids" {
  description = "List of all subnet IDs"
  value       = [for s in aws_subnet.this : s.id]
}

output "subnets_by_type" {
  description = "Map of subnet types to lists of subnet IDs"
  value = {
    for type in distinct([for s in var.subnets : s.type]) :
    type => [
      for k, v in aws_subnet.this : v.id
      if var.subnets[k].type == type
    ]
  }
}

output "subnet_details" {
  description = "Complete subnet information including IDs, CIDRs, and AZs"
  value = {
    for k, v in aws_subnet.this : k => {
      id                = v.id
      cidr_block        = v.cidr_block
      availability_zone = v.availability_zone
      type              = var.subnets[k].type
    }
  }
}