variable "vpc_id" {
  description = "VPC ID where subnets will be created"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for subnet Name tags (e.g., hub, dev)"
  type        = string
}

variable "az_count" {
  description = "How many AZs to consider from the region's available list"
  type        = number
}

variable "tags" {
  description = "Common tags applied to all subnets"
  type        = map(string)
  default     = {}
}

# === Option A: Map-based interface  ===
variable "subnets" {
  description = <<EOT
Map of subnets to create. Key becomes the name suffix.
Example:
subnets = {
  bastion  = { cidr = "10.58.0.0/20",  az_index = 0, type = "public"   }
  vm       = { cidr = "10.58.16.0/20", az_index = 0, type = "private"  }
  vpn      = { cidr = "10.58.32.0/20", az_index = 0, type = "vpn"      }
  api      = { cidr = "10.58.48.0/20", az_index = 0, type = "private"  }
  gateway  = { cidr = "10.58.64.0/20", az_index = 0, type = "private"  }
  firewall = { cidr = "10.58.80.0/20", az_index = 0, type = "firewall" }
  
}
EOT
  type = map(object({
    cidr     = string
    az_index = number   # 0..(az_count-1)
    type     = string   # public|private|vpn|firewall|api|gateway|bastion|vm|shared|aks|db
  }))

  validation {
    condition = alltrue([
      for k, v in var.subnets : (
        v.az_index >= 0 &&
        v.az_index < var.az_count &&
        can(cidrnetmask(v.cidr)) &&
        contains([
          "public","private","vpn","firewall","api","gateway","bastion","vm","shared","nlb","eks","db"
        ], v.type)
      )
    ])
    error_message = "Each subnet must have a valid CIDR, az_index within [0..az_count-1], and a supported type."
  }
}


variable "cluster_name" {
  description = "Optional EKS cluster name used to add kubernetes.io/cluster/<name> tags to subnets"
  type        = string
  default     = ""
}



