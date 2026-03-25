variable "bucket_name_prefix" {
  description = "Prefix for S3 buckets, env name will be appended"
  type        = string
}

variable "envs" {
  description = "List of environments to create buckets for"
  type        = list(string)
  default     = ["dev", "uat", "prod"]
}

variable "tags" {
  description = "Base tags to apply to all buckets"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region for S3 buckets"
  type        = string
  default     = "us-west-2"
}