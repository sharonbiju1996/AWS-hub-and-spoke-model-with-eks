# module-aws-firewall-endpoints/outputs.tf

output "firewall_id" {
  description = "Network Firewall ID"
  value       = aws_networkfirewall_firewall.this.id
}

output "firewall_arn" {
  description = "Network Firewall ARN"
  value       = aws_networkfirewall_firewall.this.arn
}

output "first_endpoint_id" {
  description = "First firewall endpoint ID (for simple routing)"
  value = try(
    [for state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states : 
      state.attachment[0].endpoint_id
    ][0],
    null
  )
}

output "all_endpoint_ids" {
  description = "All firewall endpoint IDs"
  value = try(
    [for state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states : 
      state.attachment[0].endpoint_id
    ],
    []
  )
}

output "firewall_status" {
  description = "Complete firewall status for debugging"
  value       = aws_networkfirewall_firewall.this.firewall_status
}