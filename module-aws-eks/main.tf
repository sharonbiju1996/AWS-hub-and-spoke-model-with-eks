########################################
# EKS Cluster
########################################

resource "aws_eks_cluster" "this" {
  count    = var.enabled ? 1 : 0
  name     = var.cluster_name
  role_arn = var.cluster_role_arn   #  from IAM module
  version  = "1.32"

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_cidr
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = merge(var.tags, {
    "Environment" = var.env
    "Name"        = var.cluster_name
  })

  # no IAM policy attachments here; IAM handled in separate module
}

########################################
# Cluster access for Kubernetes provider
########################################

data "aws_eks_cluster" "this" {
  count = var.enabled ? 1 : 0
  name  = aws_eks_cluster.this[0].name

}

data "aws_eks_cluster_auth" "this" {
  count = var.enabled ? 1 : 0
  name  = aws_eks_cluster.this[0].name

  
}




provider "kubernetes" {
  alias                  = "this"
  host                   = var.enabled ? data.aws_eks_cluster.this[0].endpoint : ""
  cluster_ca_certificate = var.enabled ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : ""
  token                  = var.enabled ? data.aws_eks_cluster_auth.this[0].token : ""
}




########################################
# EKS Access Entries (Admin + Terraform user)
########################################

# Cluster admin via EKSAccessEntry: EKSAdminRole
resource "aws_eks_access_entry" "admin" {
  count = var.enabled ? 1 : 0

  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = var.eks_admin_role_arn   # from IAM module
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  count = var.enabled ? 1 : 0

  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = aws_eks_access_entry.admin[0].principal_arn


  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type       = "cluster"
    namespaces = null
  }

  depends_on = [
    aws_eks_access_entry.admin,
  ]
}

# 



resource "aws_eks_access_entry" "terraform_user" {
  count = var.enabled ? 1 : 0
  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = "arn:aws:iam::289880680686:user/test"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "terraform_user_admin" {
  count = var.enabled ? 1 : 0
  cluster_name  = aws_eks_cluster.this[0].name
  principal_arn = aws_eks_access_entry.terraform_user[0].principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type       = "cluster"
    namespaces = null
  }

  depends_on = [
    aws_eks_access_entry.terraform_user,
  ]
}

########################################
# aws-auth ConfigMap (lets nodes join)
########################################

resource "kubernetes_config_map" "aws_auth" {
  count = var.enabled ? 1 : 0

  provider = kubernetes.this

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = var.node_role_arn   #  from IAM module
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }
    ])
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_access_policy_association.admin,
    aws_eks_access_policy_association.terraform_user_admin,
  ]
}

########################################
# Nodegroup
########################################

resource "aws_eks_node_group" "this" {
  count          = var.enabled ? 1 : 0
  cluster_name  = aws_eks_cluster.this[0].name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = var.node_role_arn    #  from IAM module
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  instance_types = var.instance_types
  ami_type       = "AL2_x86_64"

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  tags = merge(var.tags, {

    "Environment" = var.env
    "Name"        = "${var.cluster_name}-ng"
    "Role"        = "eks"
    "Stack"       = "spoke"
    "Env"         = var.env
  })

  depends_on = [
    kubernetes_config_map.aws_auth,
  ]

  lifecycle {
    create_before_destroy = false
  }
}
