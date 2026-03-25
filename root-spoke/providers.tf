


terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"


      version = ">= 6.2.0, < 7.0.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0, < 3.0.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0, < 3.0.0"
    }
  }
}



provider "aws" {
  region = var.aws_region


}

# Get EKS cluster details
# Get EKS cluster details for Kubernetes/Helm provider authentication



