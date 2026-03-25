variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.62.0.0/16"
}



variable "environment" {
  type    = string
  default = "Build"
}




variable "ssm_instance_profile_name" {
  description = "IAM instance profile name for SSM-enabled EC2 instances"
  type        = string
  default     = "jc-build-ssm-ec2-profile"
}




variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.62.0.0/24", "10.62.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.62.2.0/24", "10.62.3.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}


variable "agent_instance_type" {
  description = "Instance type for Azure DevOps agents"
  type        = string
  default     = "t3.medium"
}

variable "agent_desired_capacity" {
  description = "Desired number of agents"
  type        = number
  default     = 2
}

variable "agent_min_size" {
  description = "Min size of ASG"
  type        = number
  default     = 1
}

variable "agent_max_size" {
  description = "Max size of ASG"
  type        = number
  default     = 5
}

variable "azure_devops_org_url" {
  type        = string
  description = "AAzure devops organization URL"
  default     =   "https://dev.azure.com/SharonBiju0150/SharonBiju"
}

variable "azure_devops_pool_name" {
  type        = string
  description = "Agent pool name"
  default = "JC-Pipeline-Pool"
}

variable "azure_devops_pat" {
  type        = string
  sensitive   = true
  description = "PAT used to register agents"
}

variable "tags" {
  description = "Tags to apply to the VPC"
  type        = map(string)
  default     = {}
}








