resource "aws_wafv2_web_acl" "this" {
  name  = var.waf_name
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env}-api-waf"
    sampled_requests_enabled   = true
  }

  # rules { ... }
}
