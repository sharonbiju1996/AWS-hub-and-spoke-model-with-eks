# ========================================
# Core / Region
# ========================================
variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region for build VPC"
}

variable "environment" {
  type        = string
  default     = "build"
  description = "Environment name"
}

# ========================================
# Naming & Tagging
# ========================================
variable "name_prefix_override" {
  type        = string
  default     = null
  description = "Override the auto-generated name prefix"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base tags applied to all resources"
}

variable "application_name" {
  type        = string
  default     = "jcapp"
  description = "Application name for tagging"
}

variable "owner" {
  type        = string
  default     = "enfin"
  description = "Owner tag value"
}

# ========================================
# Network
# ========================================
variable "vpc_cidr" {
  type        = string
  default     = "10.63.0.0/16"
  description = "CIDR for the build VPC"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "Number of availability zones"
}

# ========================================
# Subnets
# ========================================
variable "subnets" {
  description = "Build subnet definitions"
  type = map(object({
    cidr     = string
    az_index = number
    type     = string
  }))
  default = {
    build_a = { cidr = "10.63.0.0/20",  az_index = 0, type = "private" }
    build_b = { cidr = "10.63.16.0/20", az_index = 1, type = "private" }
    agent_a = { cidr = "10.63.32.0/20", az_index = 0, type = "private" }
    agent_b = { cidr = "10.63.48.0/20", az_index = 1, type = "private" }
  }
}

# ========================================
# External CIDRs for routing
# ========================================
variable "hub_vpc_cidr" {
  type        = string
  default     = "10.58.0.0/16"
  description = "Hub VPC CIDR"
}

variable "shared_vpc_cidr" {
  type        = string
  default     = "10.62.0.0/16"
  description = "Shared VPC CIDR"
}

variable "spoke_vpc_cidrs" {
  type        = list(string)
  default     = [
    "10.59.0.0/16",  # dev
    "10.60.0.0/16",  # uat
    "10.61.0.0/16",  # prod
  ]
  description = "Spoke VPC CIDRs (dev/qa/prod)"
}

# ========================================
# Azure DevOps Agent
# ========================================
variable "enable_azdo_agent" {
  type        = bool
  default     = true
  description = "Enable Azure DevOps Agent ASG"
}

variable "azdo_agent_ami_id" {
  type        = string
  default     = ""
  description = "AMI ID for Azure DevOps Agent (from Packer)"
}

variable "azdo_agent_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Instance type for Azure DevOps Agent"
}

variable "azdo_agent_desired_capacity" {
  type        = number
  default     = 2
  description = "Desired number of agents"
}

variable "azdo_agent_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of agents"
}

variable "azdo_agent_max_size" {
  type        = number
  default     = 5
  description = "Maximum number of agents"
}
