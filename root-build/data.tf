data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "terraform-state-bucket-jc51"
    key    = "hub/terraform.tfstate"
    region = "us-west-2"
  }
}
