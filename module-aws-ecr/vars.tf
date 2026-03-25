variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten. Valid values: MUTABLE or IMMUTABLE"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository. Valid values: AES256 or KMS"
  type        = string
  default     = "AES256"
}

variable "kms_key" {
  description = "KMS key ARN to use when encryption_type is KMS"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the repository and related resources"
  type        = map(string)
  default     = {}
}

variable "lifecycle_policy_enabled" {
  description = "Whether to attach a lifecycle policy to the repository"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "JSON lifecycle policy document for the repository"
  type        = string
  default     = ""
}

variable "repository_policy_json" {
  description = "Optional repository access policy in JSON (e.g., to allow other accounts)"
  type        = string
  default     = ""
}
