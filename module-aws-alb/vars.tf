variable "name_prefix" {
  type    = string
  default = "hub"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "certificate_arn" {
  type = string
}

variable "vpce_network_interface_ids" {
  type    = list(string)
  default = []
}

variable "private_apigw_invoke_host" {
  type        = string
  default     = ""
  description = "Private API Gateway inv,oke host: <api-id>-<vpce-id>.execute-api.<region>.amazonaws.com"
}

variable "root_domain" {
  type        = string
  default     = "idukkiflavours.shop"
  description = "Root domain name"
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
