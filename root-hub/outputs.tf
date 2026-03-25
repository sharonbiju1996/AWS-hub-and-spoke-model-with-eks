output "tgw_id" {
  description = "Transit Gateway ID for spoke VPCs to attach"
  value       = module.hub_tgw.tgw_id  # or whatever the output is called in module-aws-tgw/output.tf
}

output "tgw_arn" {
  description = "Transit Gateway ARN"
  value       = module.hub_tgw.tgw_arn  # optional, but useful
}


output "tgw_rt_hub_id" {
  value = module.hub_tgw_rt_hub.route_table_id
}

output "tgw_rt_spoke_id" {
  value = module.hub_tgw_rt_spoke.route_table_id
}

output "hub_vpc_cidr" {
  value = var.vpc_cidr
}

output "tgw_rt_shared_id" {
  value = module.hub_tgw_rt_shared.route_table_id
}

output "tgw_rt_build_id" {
  description = "TGW Route Table ID for Build VPC"
  value       = module.hub_tgw_rt_build.route_table_id
}


# ========================================
# Monitoring Outputs (root-hub/monitoring-outputs.tf)
# Add these to your existing outputs.tf or create this file
# ========================================

output "monitoring_instance_id" {
  value       = var.enable_monitoring ? module.monitoring[0].instance_id : null
  description = "Monitoring EC2 instance ID"
}

output "monitoring_private_ip" {
  value       = var.enable_monitoring ? module.monitoring[0].instance_private_ip : null
  description = "Monitoring private IP"
}

output "prometheus_url" {
  value       = var.enable_monitoring ? module.monitoring[0].prometheus_url : null
  description = "Prometheus URL"
}

output "grafana_url" {
  value       = var.enable_monitoring ? module.monitoring[0].grafana_url : null
  description = "Grafana URL"
}

output "jaeger_url" {
  value       = var.enable_monitoring ? module.monitoring[0].jaeger_url : null
  description = "Jaeger UI URL"
}

output "jaeger_collector_endpoint" {
  value       = var.enable_monitoring ? module.monitoring[0].jaeger_collector_endpoint : null
  description = "Jaeger collector gRPC endpoint"
}

output "otlp_grpc_endpoint" {
  value       = var.enable_monitoring ? module.monitoring[0].otlp_grpc_endpoint : null
  description = "OTLP gRPC endpoint"
}

output "monitoring_security_group_id" {
  value       = var.enable_monitoring ? module.monitoring[0].security_group_id : null
  description = "Monitoring security group ID"
}

# ========================================
# DNS Outputs
# ========================================


# ========================================
# Ansible Variables
# ========================================
output "ansible_monitoring_vars" {
  value = var.enable_monitoring ? {
    prometheus_hub_ip          = module.monitoring[0].instance_private_ip
    jaeger_hub_ip              = module.monitoring[0].instance_private_ip
    grafana_hub_ip             = module.monitoring[0].instance_private_ip
    jaeger_collector_endpoint  = module.monitoring[0].jaeger_collector_endpoint
    otlp_grpc_endpoint         = module.monitoring[0].otlp_grpc_endpoint
  } : null
  description = "Variables for Ansible monitoring configuration"
}




# root-hub/outputs.tf

output "api_gateway_id" {
  value = module.api_gateway_hub.rest_api_id
}

output "api_gateway_execution_arn" {
  value = module.api_gateway_hub.rest_api_execution_arn
}

output "vpc_endpoint_id" {
  value = module.vpc_endpoints.apigw_vpce_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_zone_id" {
  value = module.alb.alb_zone_id
}


