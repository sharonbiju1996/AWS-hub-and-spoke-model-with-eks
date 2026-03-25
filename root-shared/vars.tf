variable "environment" {
  type        = string
  default     = "Shared"
  description = "Environment name (will use workspace if not set)"
}


variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region where resources will be created"
}

variable "name_prefix_override" {
  type        = string
  default     = null
  description = "Override the auto-generated name prefix (jc-{env})"
}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "Base tags applied to all resources"
}

variable "application_name" {
  type        = string
  default     = "jcapp-shared-infra"
  description = "Application name for tagging"
}

variable "owner" {
  type        = string
  default     = "enfin"
  description = "Owner tag value"
}

# ========================================
# Network - Hub VPC
# ========================================
variable "vpc_cidr" {
  type        = string
  default     = "10.62.0.0/16"
  description = "CIDR for the hub VPC"
}

variable "az_count" {
  type        = number
  default     = 3
  description = "How many AZs to consider from the region's available list"
}

# ========================================
# Subnets
# ========================================



variable "subnets" {
  description = "Shared services subnet definitions map"
  type = map(object({
    cidr     = string
    az_index = number
    type     = string
  }))

  default = {
    vault_a = { cidr = "10.62.0.0/20",  az_index = 0, type = "private" }
    vault_b = { cidr = "10.62.16.0/20", az_index = 1, type = "private" }

    sonar_a = { cidr = "10.62.32.0/20", az_index = 0, type = "private" }
    sonar_b = { cidr = "10.62.48.0/20", az_index = 1, type = "private" }

    # optional utilities subnet for admin/SSM jumpboxes if you want:
    mgmt_a  = { cidr = "10.62.64.0/20", az_index = 0, type = "private" }
  }
}

variable "spoke_vpc_cidrs" {
  type    = list(string)
  default = ["10.58.0.0/16", "10.59.0.0/16", "10.60.0.0/16"]
}




variable "shared_appliance_mode_support" {
  type        = bool
  default     = false
  description = "Enable TGW attachment appliance mode support"
}




# ========================================
# Vault
# ========================================
variable "enable_vault" {
  type    = bool
  default = true
}

variable "vault_instance_type" {
  type    = string
  default = "t3.small"
}

variable "vault_cluster_size" {
  type    = number
  default = 2
}



 #========================================
# SonarQube
# ========================================
variable "enable_sonarqube" {
  type        = bool
  default     = true
}

variable "sonarqube_instance_type" {
  type        = string
  default     = "t3.xlarge"
}

variable "sonarqube_volume_size" {
  type        = number
  default     = 50
}
