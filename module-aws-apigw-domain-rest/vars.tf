variable "root_domain" {
  description = "Root DNS domain (e.g. sharonlinuxstudy.org)"
  type        = string
}

variable "domain_names" {
  description = "List of fully-qualified domain names to create in API Gateway"
  type        = list(string)
}

variable "acm_cert_arn" {
  description = "ACM certificate ARN for wildcard domain"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "default_api_id" {
  description = "Default REST API ID"
  type        = string
}

variable "default_stage_name" {
  description = "Default stage name"
  type        = string
}

variable "host_routing_rules" {
  description = "List of routing rules"
  type = list(object({
    host_pattern = string
    api_id       = string
    stage        = string
    priority     = number
  }))
  default = []
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}


variable "aws_region" {
  description = "AWS region for API Gateway domain"
  type        = string
}


variable "manage_domain" {
  description = "If true, Terraform creates/manages the API GW domain. If false, use an existing one."
  type        = bool
  default     = true
}

variable "create_default_base_path_mapping" {
  description = "Whether to create the default base path mapping for this domain"
  type        = bool
  default     = true
}

