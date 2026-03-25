########################################
# EKS auth for CURRENT environment
# Uses the cluster created by module.spoke_eks
########################################

data "aws_eks_cluster" "this" {
 count = var.enable_ingress_controller ? 1 : 0
  name  = module.spoke_eks.cluster_name

 

}

data "aws_eks_cluster_auth" "this" {
  count = var.enable_ingress_controller ? 1 : 0
  name  = module.spoke_eks.cluster_name

}

########################################
# Kubernetes & Helm providers (per env)
########################################

provider "kubernetes" {
  alias                  = "eks"
  host                   = var.enable_ingress_controller ? data.aws_eks_cluster.this[0].endpoint : ""
  cluster_ca_certificate = var.enable_ingress_controller ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : ""
  token                  = var.enable_ingress_controller ? data.aws_eks_cluster_auth.this[0].token : ""
}

provider "helm" {
  alias = "eks"

  kubernetes {
    host                   = var.enable_ingress_controller ? data.aws_eks_cluster.this[0].endpoint : ""
    cluster_ca_certificate = var.enable_ingress_controller ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : ""
    token                  = var.enable_ingress_controller ? data.aws_eks_cluster_auth.this[0].token : ""
  }
}