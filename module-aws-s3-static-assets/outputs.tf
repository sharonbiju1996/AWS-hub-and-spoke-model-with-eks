output "bucket_names" {
  description = "Map of env -> bucket name"
  value       = { for env, b in aws_s3_bucket.this : env => b.bucket }
}

output "bucket_arns" {
  description = "Map of env -> bucket arn"
  value       = { for env, b in aws_s3_bucket.this : env => b.arn }
}

output "bucket_regional_domain_names" {
  description = "Map of env -> bucket regional domain name"
  value       = { for env, b in aws_s3_bucket.this : env => b.bucket_regional_domain_name }
}
