terraform {
  backend "s3" {
    bucket = "xyz-tf-project-store"
    key    = "ec2-module/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    # dynamodb_table = "terraform-lock" - this option is no longer used
    use_lockfile = true
  }
}
