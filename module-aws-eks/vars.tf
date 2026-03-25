variable "cluster_name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type    = list(string)
  default = []
}

variable "service_cidr" {
  type    = string
  default = "172.16.0.0/20"
}

variable "service_dns_ip" {
  type    = string
  default = "172.16.0.10"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "create_node_group" {
  description = "Whether to create the managed node group"
  type        = bool
  default     = true
}





variable "cluster_role_arn" {
  description = "IAM role ARN for EKS control plane"
  type        = string
}


variable "eks_admin_role_arn" {
  description = "IAM role ARN for human/admin access to EKS"
  type        = string
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN for worker nodes"
}

variable "enabled" {
  description = "Whether to create EKS resources"
  type        = bool
  default     = true
}





