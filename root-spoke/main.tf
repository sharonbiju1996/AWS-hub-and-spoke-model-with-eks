# root-spoke/main.tf

# -----------------------------
# VPC
# -----------------------------
module "spoke_vpc" {
  source   = "../module-aws-vpc"
  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr
  tags     = local.tags
}

# -----------------------------
# Subnets
# -----------------------------
module "spoke_subnets" {
  source       = "../module-aws-subnets"
  vpc_id       = module.spoke_vpc.vpc_id
  az_count     = var.az_count
  name_prefix  = local.name_prefix
  tags         = local.tags
  subnets      = local.subnet_config[local.env]
  cluster_name = "${local.name_prefix}-eks-${var.env}"
}

# -----------------------------
# TGW attachment, route tables
# -----------------------------
module "spoke_tgw_attachment" {
  source = "../module-aws-tgw-attachment"
  

  transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
  vpc_id             = module.spoke_vpc.vpc_id
  subnet_ids = [
    module.spoke_subnets.subnet_ids_by_key["eks"],
    module.spoke_subnets.subnet_ids_by_key["eks1"],
  ]

  name_prefix = local.name_prefix
  tags        = local.tags

  appliance_mode_support          = var.spoke_appliance_mode_support
  default_route_table_association = var.spoke_tgw_route_table_association
  default_route_table_propagation = var.spoke_tgw_route_table_propagation
}

module "spoke_rt" {
  source      = "../module-aws-routetable"
  vpc_id      = module.spoke_vpc.vpc_id
  name_prefix = local.name_prefix
  tags        = local.tags

  subnet_ids   = module.spoke_subnets.subnet_ids_by_key
  route_tables = local.route_tables
  associations = local.associations

  depends_on = [
    module.spoke_tgw_attachment
  ]
}



module "spoke_tgw_binding" {
  source = "../module-aws-tgw-spoke"

  attachment_id        = module.spoke_tgw_attachment.attachment_id
  hub_route_table_id   = data.terraform_remote_state.hub.outputs.tgw_rt_hub_id
  spoke_route_table_id = data.terraform_remote_state.hub.outputs.tgw_rt_spoke_id

  # Add route TO spoke VPC in other route tables
  vpc_cidr = local.vpc_cidr

  add_route_to_route_tables = {
    shared = data.terraform_remote_state.hub.outputs.tgw_rt_shared_id
    build  = data.terraform_remote_state.hub.outputs.tgw_rt_build_id
  }

  tags = local.tags

  depends_on = [module.spoke_tgw_attachment]
}






# -----------------------------
# EKS Cluster (single env: dev/qa/prod via var.env)
# -----------------------------
module "spoke_eks" {
  source = "../module-aws-eks"
  enabled = var.enable_eks
  

  # Make cluster name env-aware, e.g. jc-dev-eks
  cluster_name = "${local.name_prefix}-eks-${local.env}"
  env          = local.env

  providers = {
    kubernetes = kubernetes.eks
  }

  vpc_id = module.spoke_vpc.vpc_id

  # Only private subnets: eks + eks1
  private_subnet_ids = [
    module.spoke_subnets.subnet_ids_by_key["eks"],
    module.spoke_subnets.subnet_ids_by_key["eks1"],
  ]

  # No public subnets used for EKS
  public_subnet_ids = []

  service_cidr   = local.eks_service_cidr
  service_dns_ip = local.eks_service_dns_ip

  create_node_group = var.create_node_group

  cluster_role_arn   = module.iam.cluster_role_arn
  node_role_arn      = module.iam.node_role_arn
  eks_admin_role_arn = module.iam.eks_admin_role_arn

  tags = merge(local.tags, {
    environment = local.env
  })



}


# ========================================
# VPC INTERFACE ENDPOINTS FOR EKS NODES
# ========================================

module "spoke_vpc_endpoints" {
  source = "../module-aws-vpc-endpoints"

  name_prefix = local.name_prefix
  vpc_id      = module.spoke_vpc.vpc_id
  vpc_cidr    = local.vpc_cidr

  # Put endpoints in BOTH EKS private subnets (eks + eks1)
  subnet_ids = [
    module.spoke_subnets.subnet_ids_by_key["eks"],
    module.spoke_subnets.subnet_ids_by_key["eks1"]
  ]

  region = var.aws_region # You already have this in providers usually

  tags = local.tags

  enable_ec2         = true
  enable_ssm         = true
  enable_ssmmessages = true
  enable_ec2messages = true
}






# ========================================
# SECURITY GROUPS MODULE
# ========================================
module "security_groups" {
  source = "../module-aws-security-groups"

  name_prefix   = local.name_prefix
  vpc_id        = module.spoke_vpc.vpc_id
  vpc_cidr      = local.vpc_cidr
  create_nlb_sg = false

  tags = local.tags

  depends_on = [module.spoke_vpc]
}



# ========================================
# NGINX INGRESS CONTROLLER MODULE (DEV)
# ========================================


module "ingress_nginx" {
  source = "../module-aws-k8s-ingress"
  count  = var.enable_ingress_controller ? 1 : 0

  providers = {
    helm       = helm.eks
    kubernetes = kubernetes.eks
  }

  # Env-aware identity
  env                = local.env
  release_name       = local.release_name
  ingress_class_name = "nginx-${local.env}"
  lb_name            = local.lb_name

  ingress_namespace = local.ingress_namespace
  create_namespace  = local.ingress.create_namespace

  # Controller config
  replica_count        = local.ingress.replica_count
  load_balancer_scheme = local.ingress.load_balancer_scheme

  # Multi-tenant / CORS / SSL
  enable_cors        = local.ingress.enable_cors
  cors_allow_origin  = local.ingress.cors_allow_origin
  ssl_redirect       = local.ingress.ssl_redirect
  force_ssl_redirect = local.ingress.force_ssl_redirect

  # Proxy settings
  proxy_body_size   = local.ingress.proxy_body_size
  proxy_buffer_size = local.ingress.proxy_buffer_size

  # Autoscaling
  enable_autoscaling       = local.ingress.enable_autoscaling
  autoscaling_min_replicas = local.ingress.autoscaling_min
  autoscaling_max_replicas = local.ingress.autoscaling_max
  autoscaling_target_cpu   = local.ingress.autoscaling_target_cpu

  # Multi-tenant ingress
  create_tenant_ingress    = local.ingress.create_tenant_ingress
  tenant_ingress_name      = local.ingress.tenant_ingress_name
  tenant_ingress_namespace = local.ingress.tenant_ingress_ns
  rate_limit_rps           = local.ingress.rate_limit_rps

  tenant_hosts   = local.ingress.tenant_hosts
  eks_subnet_ids = local.eks_subnet_ids
  nlb_subnet_ids = local.eks_subnet_ids

  depends_on = [
    module.spoke_eks,

  ]
}






# IMPORTANT:
# Make sure your module-aws-k8s-ingress defines outputs:
# output "nlb_arn"      { value = data.aws_lb.ingress_controller.arn }
# output "nlb_dns_name" { value = data.aws_lb.ingress_controller.dns_name }


# root-spoke/main.tf

########################################
# API Gateway Spoke
########################################


module "api_gateway_spoke" {
  source = "../module-aws-api-gateway-spoke"

  env             = local.env
  nlb_arn         = data.aws_lb.ingress_nlb[0].arn
  nlb_dns         = data.aws_lb.ingress_nlb[0].dns_name
  rest_api_id     = data.terraform_remote_state.hub.outputs.api_gateway_id
  domain_names    = data.terraform_remote_state.hub.outputs.domain_names
  domain_name_ids = data.terraform_remote_state.hub.outputs.domain_name_ids
  waf_enabled     = var.api_waf_enabled
  waf_acl_arn     = var.api_waf_enabled ? module.waf.acl_arn : ""

  tags = merge(local.tags, {
    Environment = local.env
  })

  depends_on = [
    module.ingress_nginx
  ]
}


#}

# OR use SSM Parameter Store
# data "aws_ssm_parameter" "rds_password" {
#   name = "/${local.project_name}/${local.environment}/rds/password"
# }

# Call RDS Module






module "rds_postgres" {
  source = "../module-aws-rds"

  # Basic naming / network
  name_prefix = "${local.name_prefix}-${local.env}"
  vpc_id      = module.spoke_vpc.vpc_id


  # IMPORTANT: at least two subnets in different AZs (for your uat db + db1)


  subnet_ids = compact([
    lookup(module.spoke_subnets.subnet_ids_by_key, "db", null),
    lookup(module.spoke_subnets.subnet_ids_by_key, "db1", null),
  ])


  # Network access
  allowed_security_group_ids = []               # later you can add SG IDs here
  allowed_cidr_blocks        = [local.vpc_cidr] # allow from entire VPC

  tags = local.tags

  # Engine & sizing (from locals.current_rds_config)
  engine                 = local.current_rds_config.engine
  engine_version         = local.current_rds_config.engine_version
  parameter_group_family = local.current_rds_config.parameter_group_family
  instance_class         = local.current_rds_config.instance_class

  allocated_storage     = local.current_rds_config.allocated_storage
  max_allocated_storage = local.current_rds_config.max_allocated_storage
  storage_type          = local.current_rds_config.storage_type
  storage_encrypted     = local.current_rds_config.storage_encrypted
  kms_key_id            = null # or your KMS key if you have one

  # DB name & credentials
  db_name      = local.current_rds_config.db_name
  username     = local.current_rds_config.username
  rds_password = data.aws_secretsmanager_secret_version.rds_password.secret_string
  port         = local.current_rds_config.port

  # Networking flags
  publicly_accessible = local.current_rds_config.publicly_accessible

  # Backups & maintenance
  backup_retention_period = local.current_rds_config.backup_retention_period
  backup_window           = local.current_rds_config.backup_window
  maintenance_window      = local.current_rds_config.maintenance_window

  # Monitoring / insights
  performance_insights_enabled          = local.current_rds_config.performance_insights_enabled
  performance_insights_retention_period = local.current_rds_config.performance_insights_retention_period
  enabled_cloudwatch_logs_exports       = local.current_rds_config.enabled_cloudwatch_logs_exports

  # HA / protection / lifecycle
  multi_az                   = local.current_rds_config.multi_az
  deletion_protection        = local.current_rds_config.deletion_protection
  skip_final_snapshot        = local.current_rds_config.skip_final_snapshot
  auto_minor_version_upgrade = local.current_rds_config.auto_minor_version_upgrade
  apply_immediately          = local.current_rds_config.apply_immediately
  create_parameter_group     = local.current_rds_config.create_parameter_group

  # Parameter overrides for this env
  parameters = local.current_rds_parameters
}












module "ecr_app" {
  source = "../module-aws-ecr"

  name                 = "jc-${local.env}-app"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
  encryption_type      = "AES256"

  tags = merge(local.tags, {
    Component = "ecr-app"
  })

  lifecycle_policy_enabled = true
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}





# 1) Server for Redis + RabbitMQ
module "shared_ec2" {
  source = "../module-aws-ec2"

  # Naming
  name_prefix = "${local.name_prefix}-${local.env}"
  environment = local.env # comes from terraform.workspace

  # Networking
  vpc_id                    = module.spoke_vpc.vpc_id
  vpc_cidr                  = module.spoke_vpc.vpc_cidr
  ssm_instance_profile_name = module.iam.ssm_instance_profile_name

  # Shared private subnet (adjust to your actual output)
  shared_private_subnet_id = module.spoke_subnets.subnet_ids_by_key["shared"]

  # Instance sizes (if your module defines these variables)
  instance_type_cache_mq = "t3.small"
  instance_type_mongo    = "t3.small"

  # Keep private – SSM only
  enable_public_ip = false

}


module "waf" {
  source   = "../module-aws-waf"
  waf_name = local.waf_name
  env      = local.env
}


module "iam" {
  source      = "../module-aws-iam"
  name_prefix = "${local.name_prefix}-${local.env}"
  environment = local.env
  env         = local.env
  tags        = local.tags
}




module "shared_static_buckets" {
  count = local.env == "dev" ? 1 : 0
  source = "../module-aws-s3-static-assets"

  #bucket_name_prefix = "jc-shared-static-assets"
  bucket_name_prefix = "jc-shared-static-assets-oregon1898982" 
  envs               = ["dev", "uat", "prod"]
  tags               = local.tags
}

module "shared_cloudfront" {
  count  = local.env == "dev" ? 1 : 0  # Add this line
  source = "../module-aws-cloudfront"

  dev_bucket_domain_name  = module.shared_static_buckets[0].bucket_regional_domain_names["dev"]
  uat_bucket_domain_name  = module.shared_static_buckets[0].bucket_regional_domain_names["uat"]
  prod_bucket_domain_name = module.shared_static_buckets[0].bucket_regional_domain_names["prod"]

  dev_bucket_arn  = module.shared_static_buckets[0].bucket_arns["dev"]
  uat_bucket_arn  = module.shared_static_buckets[0].bucket_arns["uat"]
  prod_bucket_arn = module.shared_static_buckets[0].bucket_arns["prod"]

  tags = local.tags
}




