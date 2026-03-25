locals{
name_prefix = "jc-pipeline-build"
env         = terraform.workspace
vpc_name    = "${local.name_prefix}-vpc"

 tags = merge(
    var.tags,
    {
      Name        = local.vpc_name
      Application = "build-agents"
      Owner       = "enfin"
      Stack       = "build-agents"
      
      ManagedBy   = "Terraform"
    }
  )



}