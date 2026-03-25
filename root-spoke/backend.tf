#terraform {
#  backend "s3" {
 #   bucket = "terraform-state-bucket-jc51"
  #  region = "us-west-2"
    # dynamodb_table = "terraform-state-locks"
   # encrypt = true

    # This is why your path has the colon+slash
    #workspace_key_prefix = "env:" # -> env:/<workspace>/...
    #key                  = "spoke/dev/terraform.tfstate"
    #key                  ="spoke/dev/terraform.tfstate"
  #}
#}

terraform {
  backend "s3" {
    bucket               = "terraform-state-bucket-jc51"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "env:"
    key                  = "spoke/dev/terraform.tfstate"
  }
}


# UAT spoke state
#data "terraform_remote_state" "spoke_uat" {
  
  #backend =  "s3"
  #config = {
  #  bucket = "terraform-state-bucket-jc51"
   # key    = "spoke/uat/terraform.tfstate"
   # region = "us-west-2"
  #}
#}

# PROD spoke state
#data "terraform_remote_state" "spoke_prod" {
# backend = "s3"
#config = {
# bucket = "terraform-state-bucket-jc1"
#key    = "env:/prod/spoke/dev/terraform.tfstate"
#region = "ap-south-1"
#}
#}
