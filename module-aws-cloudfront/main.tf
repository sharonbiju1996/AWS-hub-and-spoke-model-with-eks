########################################
# Origin Access Control for S3
########################################



resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name = "shared-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"

  lifecycle {
    prevent_destroy = true
  }
}


########################################
# CloudFront Distribution
########################################

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Shared CloudFront for dev/uat/prod"
  default_root_object = "index.html"

  # ---------- ORIGINS ----------
  # Dev bucket origin
  origin {
    origin_id                = "dev-origin"
    domain_name              = var.dev_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # UAT bucket origin
  origin {
    origin_id                = "uat-origin"
    domain_name              = var.uat_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Prod bucket origin
  origin {
    origin_id                = "prod-origin"
    domain_name              = var.prod_bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # ---------- CACHE BEHAVIORS ----------
  # Default → prod
  default_cache_behavior {
    target_origin_id       = "prod-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress = true
  }

  # /dev/* → dev origin
  ordered_cache_behavior {
    path_pattern           = "/dev/*"
    target_origin_id       = "dev-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress = true
  }

  # /uat/* → uat origin
  ordered_cache_behavior {
    path_pattern           = "/uat/*"
    target_origin_id       = "uat-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # No custom domain for now → use default CloudFront SSL + domain
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = var.price_class

  tags = merge(
    {
      Name = "shared-cloudfront-dev-uat-prod"
    },
    var.tags
  )
}

########################################
# S3 bucket policies so only this CF can read
########################################

data "aws_iam_policy_document" "dev_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.dev_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "dev" {
  bucket = split(":::", var.dev_bucket_arn)[1]
  policy = data.aws_iam_policy_document.dev_bucket_policy.json
}

data "aws_iam_policy_document" "uat_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.uat_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "uat" {
  bucket = split(":::", var.uat_bucket_arn)[1]
  policy = data.aws_iam_policy_document.uat_bucket_policy.json
}

data "aws_iam_policy_document" "prod_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.prod_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "prod" {
  bucket = split(":::", var.prod_bucket_arn)[1]
  policy = data.aws_iam_policy_document.prod_bucket_policy.json
}
