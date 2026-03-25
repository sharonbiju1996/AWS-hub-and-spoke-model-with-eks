# root-spoke/locals.tf

locals {
  # Environment and naming
  env              = terraform.workspace
  name_prefix      = var.name_prefix_override != null ? var.name_prefix_override : "jc-${local.env}"
  #name_prefix   =  "jc"
  vpc_name         = "${local.name_prefix}-vpc"
  vpc_cidr         = lookup(var.vpc_cidr_map, local.env, var.vpc_cidr_map["default"])
  eks_cluster_name = local.env == "uat" ? "jc-uat-eks-uat" : "jc-default-eks-dev"

  # Consolidated tags
  tags = merge(
    var.tags,
    {
      Name        = local.vpc_name
      Application = var.application_name
      Owner       = var.owner
      Stack       = "spoke"
      Environment = local.env
      ManagedBy   = "Terraform"
    }
  )

  subnet_config = {
    dev = {
      eks    = { cidr = "10.59.0.0/18", az_index = 0, type = "private" }
      eks1   = { cidr = "10.59.64.0/20", az_index = 1, type = "private" }
      db     = { cidr = "10.59.128.0/20", az_index = 0, type = "private" }
      shared = { cidr = "10.59.144.0/20", az_index = 0, type = "private" }
      nlb    = { cidr = "10.59.160.0/20", az_index = 0, type = "private" }
      db1    = { cidr = "10.59.176.0/20", az_index = 1, type = "private" }
    }



    uat = {
      eks    = { cidr = "10.60.0.0/18", az_index = 0, type = "private" }
      eks1   = { cidr = "10.60.64.0/20", az_index = 1, type = "private" }
      db     = { cidr = "10.60.128.0/20", az_index = 0, type = "private" }
      shared = { cidr = "10.60.144.0/20", az_index = 0, type = "private" }
      nlb    = { cidr = "10.60.160.0/20", az_index = 0, type = "private" }
      db1    = { cidr = "10.60.176.0/20", az_index = 1, type = "private" }
    }

    prod = {
      eks    = { cidr = "10.61.0.0/18", az_index = 0, type = "private" }
      eks1   = { cidr = "10.61.64.0/20", az_index = 1, type = "private" }
      db     = { cidr = "10.61.128.0/20", az_index = 0, type = "private" }
      shared = { cidr = "10.61.144.0/20", az_index = 0, type = "private" }
      nlb    = { cidr = "10.61.160.0/20", az_index = 0, type = "private" }
      db1    = { cidr = "10.61.176.0/20", az_index = 1, type = "private" }
    }
  }


  # Build TGW routes dynamically
  tgw_routes = concat(
    var.enable_internet_via_tgw ? [
      {
        destination        = "0.0.0.0/0"
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ] : [],
    var.enable_hub_routing ? [
      {
        destination        = var.hub_vpc_cidr
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ] : [],
    var.enable_onprem_routing ? [
      {
        destination        = var.onprem_cidr
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ] : [],
     var.enable_shared_routing ? [
      {
        destination        = var.shared_cidr
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ] : [],

    var.enable_build_routing ? [
      {
        destination        = var.build_cidr
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ] : [],


    [
      for cidr in var.additional_tgw_routes : {
        destination        = cidr
        transit_gateway_id = data.aws_ec2_transit_gateway.hub_tgw.id
      }
    ]
  )



  subnets = lookup(local.subnet_config, local.env)


  # Route tables (using variable-driven configuration)
  route_tables = {
    eks = {
      routes = var.eks_route_to_tgw ? local.tgw_routes : []
    }

    eks1 = {
      routes = var.eks_route_to_tgw ? local.tgw_routes : []
    }

    db = {
      routes = var.db_isolated ? [] : local.tgw_routes
    }


    db1 = {
      routes = var.db_isolated ? [] : local.tgw_routes
    }

    shared = {
      routes = var.shared_route_to_tgw ? local.tgw_routes : []
    }

    nlb = {
      routes = var.nlb_route_to_tgw ? local.tgw_routes : []
    }
  }

  # Subnet associations
  associations = {
    eks    = { subnet_key = "eks", rt_key = "eks" }
    eks1   = { subnet_key = "eks1", rt_key = "eks1" }
    db     = { subnet_key = "db", rt_key = "db" }
    db1    = { subnet_key = "db1", rt_key = "db1" }
    shared = { subnet_key = "shared", rt_key = "shared" }
    nlb    = { subnet_key = "nlb", rt_key = "nlb" }
  }

  eks_service_cidr   = "172.16.0.0/20"
  eks_service_dns_ip = "172.16.0.10"


  eks_environments = {
    dev = {
      cluster_name = "${local.name_prefix}-eks"
      env          = "dev"
    }
    stage = {
      cluster_name = "${local.name_prefix}-eks"
      env          = "stage"
    }
    prod = {
      cluster_name = "${local.name_prefix}-eks"
      env          = "prod"
    }
  }



  ingress = {
    chart_version          = "4.11.2" # example
    replica_count          = 2
    load_balancer_scheme   = "internal"
    enable_cors            = true
    cors_allow_origin      = "*"
    ssl_redirect           = true
    force_ssl_redirect     = true
    proxy_body_size        = "50m"
    proxy_buffer_size      = "8k"
    enable_autoscaling     = true
    autoscaling_min        = 2
    autoscaling_max        = 5
    autoscaling_target_cpu = 70

    create_tenant_ingress = false
    tenant_ingress_name   = "tenant-ingress"
    tenant_ingress_ns     = "tenant-ingress"
    rate_limit_rps        = 50
    create_namespace      = true

    enable_ingress = var.enable_ingress_controller

    tenant_hosts = [] # or ["*.dev.example.com"] if you want
  }

  # You already have this from before – make sure it is the list of two EKS subnets
  eks_subnet_ids = flatten([
    lookup(module.spoke_subnets.subnet_ids_by_key, "eks", []),
    lookup(module.spoke_subnets.subnet_ids_by_key, "eks1", []),
  ])

  base_domain = var.domain_name





  # Release name and LB name per env
  release_name = "jc-${local.env}-Ingress-${local.env}" # adjust to your actual pattern
  lb_name      = local.release_name                     # or a different pattern if you want

  # LB name per env



  # Map env → ingress namespace
  # Adjust these if your real namespaces differ
  ingress_namespace = (
    local.env == "dev" ? "ingress-nginx" :
    local.env == "uat" ? "ingress-uat" :
    "ingress-${local.env}"
  )

  # Map env → Helm release name for ingress-nginx
  #  : match these to the actual `release_name` you use per env
  

  # Service name pattern from the Helm chart:
  #   <release-name>-ingress-nginx-controller





  ingress_release_name = "${local.name_prefix}-${local.env}-ingress-${local.env}"

  #  Correct: jc-dev-ingress-dev-ingress-nginx-controller
  ingress_service_name = "${local.ingress_release_name}-ingress-nginx-controller"

  #  Correct tag: ingress-nginx/jc-dev-ingress-dev-ingress-nginx-controller
  ingress_service_tag  = "${var.ingress_namespace}/${local.ingress_service_name}"



  # RDS Configuration per workspace
  rds_config = {
    dev = {
      engine                                = "postgres"
      engine_version                        = "16"
      parameter_group_family                = "postgres16"
      instance_class                        = "db.t3.micro"
      allocated_storage                     = 20
      max_allocated_storage                 = 100
      storage_type                          = "gp3"
      storage_encrypted                     = true
      db_name                               = "devdb"
      username                              = "postgres"
      port                                  = 5432
      publicly_accessible                   = false
      backup_retention_period               = 7
      backup_window                         = "03:00-04:00"
      maintenance_window                    = "mon:04:00-mon:05:00"
      multi_az                              = false
      deletion_protection                   = false
      skip_final_snapshot                   = true
      performance_insights_enabled          = true
      performance_insights_retention_period = 7
      enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
      auto_minor_version_upgrade            = true
      apply_immediately                     = false
      create_parameter_group                = true
    }

    uat = {
      engine                                = "postgres"
      engine_version                        = "16"
      parameter_group_family                = "postgres16"
      instance_class                        = "db.t3.small"
      allocated_storage                     = 50
      max_allocated_storage                 = 200
      storage_type                          = "gp3"
      storage_encrypted                     = true
      db_name                               = "stagingdb"
      username                              = "postgres"
      port                                  = 5432
      publicly_accessible                   = false
      backup_retention_period               = 14
      backup_window                         = "03:00-04:00"
      maintenance_window                    = "mon:04:00-mon:05:00"
      multi_az                              = false
      deletion_protection                   = false
      skip_final_snapshot                   = true
      performance_insights_enabled          = true
      performance_insights_retention_period = 7
      enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
      auto_minor_version_upgrade            = true
      apply_immediately                     = false
      create_parameter_group                = true
    }

    prod = {
      engine                                = "postgres"
      engine_version                        = "16"
      parameter_group_family                = "postgres16"
      instance_class                        = "db.r6g.xlarge"
      allocated_storage                     = 200
      max_allocated_storage                 = 1000
      storage_type                          = "gp3"
      storage_encrypted                     = true
      db_name                               = "proddb"
      username                              = "postgres"
      port                                  = 5432
      publicly_accessible                   = false
      backup_retention_period               = 30
      backup_window                         = "03:00-04:00"
      maintenance_window                    = "mon:04:00-mon:05:00"
      multi_az                              = true
      deletion_protection                   = true
      skip_final_snapshot                   = false
      performance_insights_enabled          = true
      performance_insights_retention_period = 731
      enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
      auto_minor_version_upgrade            = true
      apply_immediately                     = false
      create_parameter_group                = true
    }
  }

  # Get current workspace config
  current_rds_config = local.rds_config[local.env]

  # RDS Parameters per workspace
  rds_parameters_by_env = {
    dev = [
     # {
       # name  = "shared_preload_libraries"
        #value = "pg_stat_statements"
      #}#,
      {
        name  = "log_statement"
        value = "all"
      },
      {
        name  = "log_min_duration_statement"
        value = "1000"
      },
     # {
      #  name  = "max_connections"
       # value = "100"
      #},
      #{
       # name  = "shared_buffers"
       # value = "{DBInstanceClassMemory/32768}"
      #},
      {
        name  = "effective_cache_size"
        value = "{DBInstanceClassMemory/16384}"
      },
      {
        name  = "work_mem"
        value = "10485"
      },
      {
        name  = "maintenance_work_mem"
        value = "2097152"
      },
      {
        name  = "random_page_cost"
        value = "1.1"
      },
      {
        name  = "effective_io_concurrency"
        value = "200"
      }
    ]

    uat = [
      # {
      #  name  = "shared_preload_libraries"
      # value = "pg_stat_statements"
      #},
      {
        name  = "log_statement"
        value = "ddl"
      },
      {
        name  = "log_min_duration_statement"
        value = "500"
      },
      #{
      # name  = "max_connections"
      #value = "150"
      #},
      #{
      # name  = "shared_buffers"
      #value = "{DBInstanceClassMemory/32768}"
      #},
      {
        name  = "effective_cache_size"
        value = "{DBInstanceClassMemory/16384}"
      },
      {
        name  = "work_mem"
        value = "15728"
      },
      {
        name  = "maintenance_work_mem"
        value = "2097152"
      },
      {
        name  = "random_page_cost"
        value = "1.1"
      },
      {
        name  = "effective_io_concurrency"
        value = "200"
      }
    ]

    prod = [
      #{
       # name  = "shared_preload_libraries"
        #value = "pg_stat_statements,pg_hint_plan"
      #},
      {
        name  = "log_statement"
        value = "ddl"
      },
      {
        name  = "log_min_duration_statement"
        value = "500"
      },
      #{
       # name  = "max_connections"
        #value = "300"
      #},
      #{
       # name  = "shared_buffers"
        #value = "{DBInstanceClassMemory/32768}"
      #},
      {
        name  = "effective_cache_size"
        value = "{DBInstanceClassMemory/16384}"
      },
      {
        name  = "work_mem"
        value = "20971"
      },
      {
        name  = "maintenance_work_mem"
        value = "4194304"
      },
      {
        name  = "checkpoint_completion_target"
        value = "0.9"
      },
      {
        name  = "wal_buffers"
        value = "16384"
      },
      {
        name  = "default_statistics_target"
        value = "100"
      },
      {
        name  = "random_page_cost"
        value = "1.1"
      },
      {
        name  = "effective_io_concurrency"
        value = "200"
      },
      {
        name  = "min_wal_size"
        value = "4096"
      },
      {
        name  = "max_wal_size"
        value = "16384"
      }
    ]
  }

  # Get current workspace parameters
  current_rds_parameters = local.rds_parameters_by_env[local.env]



  # Security group IDs allowed to access RDS (e.g., EKS nodes, bastion)
  rds_allowed_security_groups = [
    # Add security group IDs here, or reference from other modules
    # module.eks.node_security_group_id,
    # module.bastion.security_group_id,
  ]

  # CIDR blocks allowed to access RDS
  rds_allowed_cidrs = [
    # module.vpc.vpc_cidr_block,  # Allow from entire VPC
  ]

  env_priority = {
    dev  = 10
    uat  = 20
    prod = 30
  }

  root_domain       = "idukkiflavours.shop"

  tenant_zone_name = "idukkiflavours.shop"
                    # "dev", "qa", "prod", etc.

  cloudfront_acm_cert_arn = "arn:aws:acm:us-east-1:289880680686:certificate/b353a77b-23fd-4041-b363-987b23df616d"
                  

  waf_name = "jc-${local.env}-waf"


}


