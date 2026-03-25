variable "vpc_id" {
  description = "VPC ID where agents will run"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 5
}

variable "azure_devops_org_url" {
  type        = string
  description = "https://dev.azure.com/SharonBiju0150"
}

variable "azure_devops_pool_name" {
  type        = string
  default     = "JC-Azure-Agents"
}

variable "azure_devops_pat" {
  description = "Azure DevOps PAT"
  type        = string
  sensitive   = true
}

variable "agent_name_prefix" {
  type        = string
  default     = "azdo-agent"
}

variable "name_prefix" {
  type        = string
  default     = "jc-build"
}

variable "tags" {
  type    = map(string)
  default = {}
}
