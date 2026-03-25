variable "dev_bucket_domain_name" {
  description = "Regional domain name of the dev S3 bucket"
  type        = string
}

variable "uat_bucket_domain_name" {
  description = "Regional domain name of the UAT S3 bucket"
  type        = string
}

variable "prod_bucket_domain_name" {
  description = "Regional domain name of the prod S3 bucket"
  type        = string
}

variable "dev_bucket_arn" {
  description = "ARN of the dev S3 bucket"
  type        = string
}

variable "uat_bucket_arn" {
  description = "ARN of the UAT S3 bucket"
  type        = string
}

variable "prod_bucket_arn" {
  description = "ARN of the prod S3 bucket"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Tags to apply to the CloudFront distribution"
  type        = map(string)
  default     = {}
}
