########################################
# Hub remote state (for TGW, etc.)
########################################

data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "terraform-state-bucket-jc51"
    key    = "hub/terraform.tfstate"
    region = "us-west-2"
  }
}

########################################
# Discover the NLB created by ingress-nginx
########################################

# NLB itself, found by the Kubernetes service tag



data "aws_lb" "ingress_nlb" {
  count = var.enable_ingress_controller ? 1 : 0

  tags = {
    "Environment" = local.env
  }

  depends_on = [
    module.ingress_nginx,
  ]
}

data "aws_lb_listener" "ingress_nlb_http" {
  count = var.enable_ingress_controller ? 1 : 0

  load_balancer_arn = data.aws_lb.ingress_nlb[count.index].arn
  port              = 80

  depends_on = [
    module.ingress_nginx,
  ]
}






#data "aws_acm_certificate" "existing" {#
 # domain      = "idukkiflavours.shop"
  #statuses    = ["ISSUED"]
  #most_recent = true
#}


#data "aws_api_gateway_domain_name" "existing" {
 # domain_name = "*.idukkiflavours.shop"
#}



########################################
# RDS Secret from Secrets Manager
########################################


data "aws_secretsmanager_secret" "rds_password" {
  name = "arn:aws:secretsmanager:us-west-2:289880680686:secret:sufl/db/stage-BsZR6k"
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}


########################################
# Hub TGW from remote state
########################################

data "aws_ec2_transit_gateway" "hub_tgw" {
  id = data.terraform_remote_state.hub.outputs.tgw_id
}
