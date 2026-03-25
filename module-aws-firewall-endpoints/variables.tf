# module-aws-firewall-endpoints/variables.tf

variable "vpc_id" {
  description = "VPC ID where firewall will be deployed"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "firewall_subnet_ids" {
  description = "List of firewall subnet IDs"
  type        = list(string)
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "policy_stateless_default_actions" {
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
  description = "Default actions for stateless packets"
}

variable "policy_stateless_fragment_default_actions" {
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
  description = "Default actions for stateless fragmented packets"
}

variable "rule_capacity" {
  type        = number
  default     = 100
  description = "The maximum number of operating resources that this rule group can use"
}
