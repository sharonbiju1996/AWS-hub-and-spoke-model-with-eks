output "distribution_id" {
  value = aws_cloudfront_distribution.tenant_wildcard.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.tenant_wildcard.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.tenant_wildcard.hosted_zone_id
}
