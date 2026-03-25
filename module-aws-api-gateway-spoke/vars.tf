variable "env" {
  type = string
}

variable "nlb_arn" {
  type = string
}

variable "nlb_dns" {
  type = string
}

variable "rest_api_id" {
  type = string
}

variable "domain_names" {
  type = map(string)
}

variable "domain_name_ids" {
  type = map(string)
}

variable "waf_enabled" {
  type    = bool
  default = false
}

variable "waf_acl_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
