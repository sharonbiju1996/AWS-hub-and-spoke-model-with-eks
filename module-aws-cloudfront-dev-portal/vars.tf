variable "env" { 
  type = string 
  }

variable "zone_name" {
  type        = string
  description = "Base zone, e.g. idukkiflavours.shop"
}

variable "route53_zone_id" {
  type = string
}

variable "acm_cert_arn_us_east_1" {
  type        = string
  description = "ACM cert ARN in us-east-1 (imported wildcard cert is OK)"
  default  = "arn:aws:acm:us-east-1:289880680686:certificate/b353a77b-23fd-4041-b363-987b23df616d"
}

variable "apigw_origin_domain" {
  type        = string
  description = "API Gateway domain WITHOUT https:// (either execute-api domain or custom domain)"
}

variable "apigw_origin_path" {
  type        = string
  description = "Usually /dev or /uat if using execute-api; empty string if using custom domain base path mapping"
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
