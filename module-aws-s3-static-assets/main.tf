locals {
  envs = toset(var.envs)
}

resource "aws_s3_bucket" "this" {
  for_each = local.envs
  region   = var.region 

  bucket = "${var.bucket_name_prefix}-${each.key}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.bucket_name_prefix}-${each.key}"
      Environment = each.key
    }
  )
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
