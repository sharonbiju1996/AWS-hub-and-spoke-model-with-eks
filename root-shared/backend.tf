terraform {
  backend "s3" {
    bucket               = "terraform-state-bucket-jc51" # ← Change this!
    key                  = "spoke/shared/terraform.tfstate"
    region               = "us-west-2"
   # workspace_key_prefix = "env:"
  }
}