########################################
# Helm Release Variables
########################################

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_repository" {
  description = "Helm chart repository"
  type        = string
  default     = "https://kubernetes.github.io/ingress-nginx"
}

variable "chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = "4.11.0"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "ingress-nginx"
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = true
}

########################################
# Controller Configuration
########################################

variable "replica_count" {
  description = "Number of controller replicas"
  type        = number
  default     = 2
}

variable "load_balancer_scheme" {
  description = "Load balancer scheme (internal or internet-facing)"
  type        = string
  default     = "internal"
}

variable "service_annotations" {
  description = "Additional service annotations"
  type        = map(string)
  default     = {}
}

variable "additional_config" {
  description = "Additional controller configuration"
  type        = map(string)
  default     = {}
}

variable "custom_headers" {
  description = "Custom headers to add"
  type        = map(string)
  default = {
    "X-Forwarded-Proto" = "https"
  }
}

########################################
# SSL/TLS Configuration
########################################

variable "ssl_redirect" {
  description = "Enable SSL redirect"
  type        = bool
  default     = false
}

variable "force_ssl_redirect" {
  description = "Force SSL redirect"
  type        = bool
  default     = false
}

########################################
# CORS Configuration
########################################

variable "enable_cors" {
  description = "Enable CORS"
  type        = bool
  default     = true
}

variable "cors_allow_origin" {
  description = "CORS allow origin"
  type        = string
  default     = "*"
}

variable "cors_allow_methods" {
  description = "CORS allow methods"
  type        = string
  default     = "GET, PUT, POST, DELETE, PATCH, OPTIONS"
}

variable "cors_allow_headers" {
  description = "CORS allow headers"
  type        = string
  default     = "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization,X-Tenant-Id,X-Forwarded-Host"
}

########################################
# Proxy Configuration
########################################

variable "proxy_buffer_size" {
  description = "Proxy buffer size"
  type        = string
  default     = "16k"
}

variable "proxy_body_size" {
  description = "Proxy body size"
  type        = string
  default     = "100m"
}

variable "proxy_connect_timeout" {
  description = "Proxy connect timeout in seconds"
  type        = number
  default     = 30
}

variable "proxy_send_timeout" {
  description = "Proxy send timeout in seconds"
  type        = number
  default     = 30
}

variable "proxy_read_timeout" {
  description = "Proxy read timeout in seconds"
  type        = number
  default     = 30
}

variable "custom_http_errors" {
  description = "Custom HTTP error codes"
  type        = string
  default     = "404,503"
}

########################################
# Monitoring Configuration
########################################

variable "enable_metrics" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "enable_service_monitor" {
  description = "Enable ServiceMonitor for Prometheus Operator"
  type        = bool
  default     = false
}

variable "pod_annotations" {
  description = "Pod annotations"
  type        = map(string)
  default = {
    "prometheus.io/scrape" = "true"
    "prometheus.io/port"   = "10254"
  }
}

########################################
# Resource Configuration
########################################

variable "resources_requests_cpu" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "resources_requests_memory" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "resources_limits_cpu" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "resources_limits_memory" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

########################################
# Autoscaling Configuration
########################################

variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "autoscaling_min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 2
}

variable "autoscaling_max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "autoscaling_target_cpu" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 80
}

variable "autoscaling_target_memory" {
  description = "Target memory utilization percentage"
  type        = number
  default     = 80
}

########################################
# Multi-Tenant Ingress Configuration
########################################

variable "create_tenant_ingress" {
  description = "Create multi-tenant ingress resource"
  type        = bool
  default     = false
}

variable "tenant_ingress_name" {
  description = "Name of the tenant ingress"
  type        = string
  default     = "multi-tenant-ingress"
}

variable "tenant_ingress_namespace" {
  description = "Namespace for tenant ingress"
  type        = string
  default     = "default"
}

variable "tenant_ingress_annotations" {
  description = "Additional annotations for tenant ingress"
  type        = map(string)
  default     = {}
}

variable "tenant_routing_snippet" {
  description = "Custom tenant routing configuration snippet"
  type        = string
  default     = ""
}

variable "rate_limit_rps" {
  description = "Rate limit requests per second"
  type        = string
  default     = "100"
}

variable "tenant_hosts" {
  description = "List of tenant host patterns"
  type        = list(string)
  default     = ["*.dev.example.com"]
}

variable "tenant_paths" {
  description = "List of paths for tenant routing"
  type = list(object({
    path         = string
    path_type    = string
    service_name = string
    service_port = number
  }))
  default = [
    {
      path         = "/"
      path_type    = "Prefix"
      service_name = "tenant-application-service"
      service_port = 80
    }
  ]
}

########################################
# Tenant Routing ConfigMap
########################################

variable "create_tenant_routing_configmap" {
  description = "Create ConfigMap for tenant routing logic"
  type        = bool
  default     = false
}

variable "tenant_routing_configmap_name" {
  description = "Name of tenant routing ConfigMap"
  type        = string
  default     = "tenant-routing-config"
}

variable "tenant_routing_config" {
  description = "Custom tenant routing configuration"
  type        = string
  default     = ""
}

variable "base_domain" {
  description = "Base domain for tenant routing"
  type        = string
  default     = "dev.example.com"
}

variable "nlb_subnet_ids" {
  type = list(string)
}


variable "eks_subnet_ids" {
  type = list(string)
}

variable "env" {
  description = "Environment name (dev, uat, prod)"
  type        = string
}

variable "ingress_class_name" {
  type        = string
  description = "Kubernetes IngressClass name to use (e.g. nginx, nginx-uat)"
  default     = "nginx"
}

variable "lb_name" {
  type        = string
  description = "AWS NLB name for this ingress controller"
}


variable "ingress_namespace" {
  description = "Namespace where the ingress-nginx controller is deployed"
  type        = string
}




