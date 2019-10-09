// aws provider
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws-account]
  alias               = "main" // CHANGE_IT

  // skip some validations to speed up TF
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

// optional, comment out if not used
terraform {
  required_version = ">= 0.12"

  backend "s3" {
    region = "region"      // CHANGE_IT
    bucket = "bucket name" // CHANGE_IT
    key    = "state/op-scim-example-env.tfstate"

    encrypt = "true"
    acl     = "bucket-owner-full-control"
  }
}
