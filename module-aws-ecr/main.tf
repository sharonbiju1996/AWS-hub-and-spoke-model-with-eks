locals {
  use_kms = var.encryption_type == "KMS" && var.kms_key != null
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = local.use_kms ? var.kms_key : null
  }

  tags = var.tags
}

# Optional lifecycle policy
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy_enabled && var.lifecycle_policy != "" ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

# Optional repository policy (cross-account access, etc.)
resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy_json != "" ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy_json
}
