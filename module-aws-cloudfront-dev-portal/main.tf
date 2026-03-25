locals {
  wildcard_alias = "*.${var.zone_name}"
  origin_id      = "apigw-${var.env}"
}

# CloudFront Function: send viewer Host to origin using x-tenant-domain
resource "aws_cloudfront_function" "tenant_header" {
  name    = "${var.env}-tenant-header"
  runtime = "cloudfront-js-1.0"
  comment = "Inject x-tenant-domain and x-portal from Host"
  publish = true

  code = <<EOF
function handler(event) {
  var request = event.request;
  var host = request.headers.host.value;

  // always pass original host
  request.headers["x-tenant-domain"] = { value: host };

  // mark admin vs tenant (optional, helps you separate admin portal)
  if (host === "admin-${var.env}" + "." + "${var.zone_name}") {
    request.headers["x-portal"] = { value: "admin" };
  } else {
    request.headers["x-portal"] = { value: "tenant" };
  }

  return request;
}
EOF
}

# Origin Request Policy: forward headers/cookies/query to API Gateway
# IMPORTANT: CloudFront does NOT allow "Authorization" in Origin Request Policy
resource "aws_cloudfront_origin_request_policy" "to_apigw" {
  name    = "${var.env}-to-apigw-origin-request"
  comment = "Forward tenant headers + cookies/query to API Gateway (no Authorization)"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "x-tenant-domain",
        "x-portal",
        "Origin",
        "Referer",
        "User-Agent",
        "Accept",
        "Content-Type"
      ]
    }
  }

  cookies_config {
    cookie_behavior = "all"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# Cache Policy: near-no-cache (TTL 1s) + forward Authorization via cache policy
# NOTE: CloudFront rejects EnableAcceptEncoding* and HeaderBehavior rules when caching is truly disabled (TTL=0).
resource "aws_cloudfront_cache_policy" "no_cache_with_auth" {
  name    = "${var.env}-no-cache-with-auth"
  comment = "Near-no-cache (TTL=1s) but forward Authorization via cache policy"

  default_ttl = 1
  min_ttl     = 0
  max_ttl     = 1

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "tenant_wildcard" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "Wildcard tenant frontend ${var.env}"
  price_class     = "PriceClass_100"

  # Wildcard alias (e.g. *.example.com)
  aliases = [local.wildcard_alias]

  origin {
    # Best: point to API Gateway custom domain (api-dev.example.com),
    # or the execute-api domain if you don't have custom domain.
    domain_name = var.apigw_origin_domain
    origin_id   = local.origin_id

    # If your origin is execute-api, keep stage path here.
    # If your origin is a custom domain with base path mapping, set this to "".
    origin_path = var.apigw_origin_path

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id          = aws_cloudfront_cache_policy.no_cache_with_auth.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.to_apigw.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.tenant_header.arn
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_cert_arn_us_east_1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, { Environment = var.env })
}

# Route53 wildcard record -> CloudFront
#resource "aws_route53_record" "wildcard_cf" {
 # zone_id = var.route53_zone_id
  #name    = "*.${var.zone_name}"
  #type    = "A"

  #alias {
    #name                   = aws_cloudfront_distribution.tenant_wildcard.domain_name
    #zone_id                = aws_cloudfront_distribution.tenant_wildcard.hosted_zone_id
    #evaluate_target_health = false
  #}
#}
