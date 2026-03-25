output "customer_gateway_id" {
  description = "The ID of the Customer Gateway"
  value       = aws_customer_gateway.this.id
}

output "vpn_connection_id" {
  description = "The ID of the VPN Connection"
  value       = aws_vpn_connection.this.id
}

output "vpn_gateway_id" {
  description = "The ID of the VPN Gateway (VGW) if created"
  value       = try(aws_vpn_gateway.this[0].id, null)
}

output "transit_gateway_attachment_id" {
  description = "The TGW attachment ID when VPN is terminated on a TGW"
  value       = try(aws_vpn_connection.this.transit_gateway_attachment_id, null)
}

output "customer_gateway_configuration" {
  description = "Full AWS-generated customer gateway configuration (XML)"
  value       = aws_vpn_connection.this.customer_gateway_configuration
  sensitive   = true
}

output "tunnel_details" {
  description = "Useful tunnel details for on-prem configuration"
  value = {
    tunnel1_address      = aws_vpn_connection.this.tunnel1_address
    tunnel1_inside_cidr  = aws_vpn_connection.this.tunnel1_inside_cidr
    tunnel1_ike_versions = aws_vpn_connection.this.tunnel1_ike_versions

    tunnel2_address      = aws_vpn_connection.this.tunnel2_address
    tunnel2_inside_cidr  = aws_vpn_connection.this.tunnel2_inside_cidr
    tunnel2_ike_versions = aws_vpn_connection.this.tunnel2_ike_versions
  }
  sensitive = true
}

output "tgw_attachment_id" {
  description = "Transit Gateway attachment ID for this VPN"
  value       = aws_vpn_connection.this.transit_gateway_attachment_id
}
