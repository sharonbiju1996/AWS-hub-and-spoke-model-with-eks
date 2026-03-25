########################################
# Locals
########################################

locals {
  # Helm / K8s names must be lowercase RFC 1123
  release_name_sanitized = lower(var.release_name)
}

########################################
# Helm Release: NGINX Ingress Controller
########################################
resource "helm_release" "ingress_nginx" {
  name       = local.release_name_sanitized
  repository = var.chart_repository
  chart      = var.chart_name
  version    = var.chart_version

  namespace        = var.ingress_namespace
  create_namespace = var.create_namespace

  timeout = 900
  wait    = true
  atomic  = false

  values = [
    yamlencode({
      controller = {
        replicaCount = var.replica_count

        service = {
          type = "LoadBalancer"
          annotations = merge(
            {
              # Use EKS in-tree controller to create an internal NLB
              "service.beta.kubernetes.io/aws-load-balancer-type"                     = "nlb"
              "service.beta.kubernetes.io/aws-load-balancer-internal"                 = "true"
              "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "Environment=${var.env},Role=apigw-ingress"
            },
            var.service_annotations
          )
        }

        config = merge(
          {
            "use-forwarded-headers"      = "true"
            "compute-full-forwarded-for" = "true"
            "use-proxy-protocol"         = "false"
            "log-format-upstream"        = "$remote_addr - $remote_user [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" $request_length $request_time [$proxy_upstream_name] [$proxy_alternative_upstream_name] $upstream_addr $upstream_response_length $upstream_response_time $upstream_status $req_id $http_x_tenant_id $http_host"
            "enable-real-ip"             = "true"
            "ssl-redirect"               = var.ssl_redirect
            "force-ssl-redirect"         = var.force_ssl_redirect
            "custom-http-errors"         = var.custom_http_errors
            "proxy-buffer-size"          = var.proxy_buffer_size
            "proxy-body-size"            = var.proxy_body_size
            "enable-cors"                = var.enable_cors
            "cors-allow-origin"          = var.cors_allow_origin
            "cors-allow-methods"         = var.cors_allow_methods
            "cors-allow-headers"         = var.cors_allow_headers
          },
          var.additional_config
        )

        addHeaders = var.custom_headers

        metrics = {
          enabled = var.enable_metrics
          serviceMonitor = {
            enabled = var.enable_service_monitor
          }
        }

        podAnnotations = var.pod_annotations

        resources = {
          requests = {
            cpu    = var.resources_requests_cpu
            memory = var.resources_requests_memory
          }
          limits = {
            cpu    = var.resources_limits_cpu
            memory = var.resources_limits_memory
          }
        }

        autoscaling = var.enable_autoscaling ? {
          enabled                           = true
          minReplicas                       = var.autoscaling_min_replicas
          maxReplicas                       = var.autoscaling_max_replicas
          targetCPUUtilizationPercentage    = var.autoscaling_target_cpu
          targetMemoryUtilizationPercentage = var.autoscaling_target_memory
        } : {
          enabled                           = false
          minReplicas                       = null
          maxReplicas                       = null
          targetCPUUtilizationPercentage    = null
          targetMemoryUtilizationPercentage = null
        }
      }
    })
  ]

  set {
    name  = "controller.ingressClassResource.name"
    value = var.ingress_class_name
  }

  set {
    name  = "controller.ingressClass"
    value = var.ingress_class_name
  }

 
}

########################################
# Multi-Tenant Ingress Resource
########################################

resource "kubernetes_ingress_v1" "tenant_ingress" {
  count = var.create_tenant_ingress ? 1 : 0

  metadata {
    name      = var.tenant_ingress_name
    namespace = var.tenant_ingress_namespace

    annotations = merge(
      {
        "kubernetes.io/ingress.class" = "nginx"

        "nginx.ingress.kubernetes.io/upstream-vhost" = "$host"

        "nginx.ingress.kubernetes.io/limit-rps" = var.rate_limit_rps

        "nginx.ingress.kubernetes.io/enable-cors"        = var.enable_cors ? "true" : "false"
        "nginx.ingress.kubernetes.io/cors-allow-origin"  = var.cors_allow_origin
        "nginx.ingress.kubernetes.io/cors-allow-methods" = var.cors_allow_methods
        "nginx.ingress.kubernetes.io/cors-allow-headers" = var.cors_allow_headers

        "nginx.ingress.kubernetes.io/ssl-redirect"       = var.ssl_redirect ? "true" : "false"
        "nginx.ingress.kubernetes.io/force-ssl-redirect" = var.force_ssl_redirect ? "true" : "false"

        "nginx.ingress.kubernetes.io/proxy-body-size"       = var.proxy_body_size
        "nginx.ingress.kubernetes.io/proxy-connect-timeout" = tostring(var.proxy_connect_timeout)
        "nginx.ingress.kubernetes.io/proxy-send-timeout"    = tostring(var.proxy_send_timeout)
        "nginx.ingress.kubernetes.io/proxy-read-timeout"    = tostring(var.proxy_read_timeout)

        "nginx.ingress.kubernetes.io/custom-http-errors"    = var.custom_http_errors
      },
      var.tenant_ingress_annotations
    )
  }

  spec {
    ingress_class_name = "nginx"

    dynamic "rule" {
      for_each = var.tenant_hosts
      content {
        host = rule.value

        http {
          dynamic "path" {
            for_each = var.tenant_paths
            content {
              path      = path.value.path
              path_type = path.value.path_type

              backend {
                service {
                  name = path.value.service_name
                  port {
                    number = path.value.service_port
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]
}

########################################
# ConfigMap for tenant routing logic
########################################

resource "kubernetes_config_map" "tenant_routing" {
  count = var.create_tenant_routing_configmap ? 1 : 0

  metadata {
    name      = var.tenant_routing_configmap_name
    namespace = var.namespace
  }

  data = {
    "tenant-routing.conf" = var.tenant_routing_config != "" ? var.tenant_routing_config : <<-EOT
      map $http_host $tenant_id {
        ~^(?<tenant>[^.]+)\.${var.base_domain}$ $tenant;
        default "unknown";
      }

      map $tenant_id $rate_limit_zone {
        "premium-tenant" "premium";
        default "standard";
      }
    EOT
  }

  depends_on = [helm_release.ingress_nginx]
}

########################################
# (Removed) Data Source to Discover NLB
########################################
# We intentionally do NOT look up the AWS LB from Terraform anymore.
# The EKS in-tree service-controller manages the NLB lifecycle based on
# the Service type=LoadBalancer and the annotations above.
#
# If in the future you want Terraform to know the LB DNS name or ARN,
# we can add a *separate* data source that discovers it by tag or hostname.







