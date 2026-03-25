################################################################################
# ALB
################################################################################
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = var.tags
}

################################################################################
# Security Group
################################################################################
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

################################################################################
# Target Group - VPC Endpoint
################################################################################
resource "aws_lb_target_group" "vpce" {
  name        = "${var.name_prefix}-vpce-tg"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "443"
    protocol            = "HTTPS"
    matcher             = "200-499"
  }

  tags = var.tags
}

locals {
  vpce_eni_map = { for idx, eni_id in var.vpce_network_interface_ids : tostring(idx) => eni_id }
}

data "aws_network_interface" "vpce" {
  for_each = local.vpce_eni_map
  id       = each.value
}

resource "aws_lb_target_group_attachment" "vpce" {
  for_each         = data.aws_network_interface.vpce
  target_group_arn = aws_lb_target_group.vpce.arn
  target_id        = each.value.private_ip
  port             = 443
}

################################################################################
# HTTPS Listener
################################################################################
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpce.arn
  }
}

################################################################################
# Listener Rule - DEV Environment (*-dev.*)
################################################################################
resource "aws_lb_listener_rule" "dev" {
  count        = var.private_apigw_invoke_host != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpce.arn
  }

  condition {
    host_header {
      values = ["*-dev.${var.root_domain}"]
    }
  }

  # Transform 1: Host header rewrite
  transform {
    type = "host-header-rewrite"

    host_header_rewrite_config {
      rewrite {
        regex   = "^(.*)$"
        replace = var.private_apigw_invoke_host
      }
    }
  }

  # Transform 2: URL rewrite (add /dev/ prefix)
  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/(.*)$"
        replace = "/dev/$1"
      }
    }
  }
}

################################################################################
# Listener Rule - UAT Environment (*-uat.*)
################################################################################
resource "aws_lb_listener_rule" "uat" {
  count        = var.private_apigw_invoke_host != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpce.arn
  }

  condition {
    host_header {
      values = ["*-uat.${var.root_domain}"]
    }
  }

  transform {
    type = "host-header-rewrite"

    host_header_rewrite_config {
      rewrite {
        regex   = "^(.*)$"
        replace = var.private_apigw_invoke_host
      }
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/(.*)$"
        replace = "/uat/$1"
      }
    }
  }
}

################################################################################
# Listener Rule - PROD Environment (*-prod.*)
################################################################################
resource "aws_lb_listener_rule" "prod" {
  count        = var.private_apigw_invoke_host != "" ? 1 : 0
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpce.arn
  }

  condition {
    host_header {
      values = ["*-prod.${var.root_domain}"]
    }
  }

  transform {
    type = "host-header-rewrite"

    host_header_rewrite_config {
      rewrite {
        regex   = "^(.*)$"
        replace = var.private_apigw_invoke_host
      }
    }
  }

  transform {
    type = "url-rewrite"

    url_rewrite_config {
      rewrite {
        regex   = "^/(.*)$"
        replace = "/prod/$1"
      }
    }
  }
}

################################################################################
# HTTP Redirect
################################################################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

################################################################################
# WAF Association (Optional)
################################################################################
resource "aws_wafv2_web_acl_association" "alb" {
  count        = var.waf_enabled ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_acl_arn
}
