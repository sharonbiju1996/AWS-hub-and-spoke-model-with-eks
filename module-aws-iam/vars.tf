

variable "env" {
  description = "Environment (dev/uat/prod)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}


variable "cluster_name" {
  type        = string
  default     = null
  description = "Optional cluster name — used only if caller passes it in"
}

variable "environment" {
  description = "Environment name (dev/uat/prod/etc)"
  type        = string
}


variable "name_prefix" {
  type        = string
  description = "Prefix for IAM resource names"
}