// aws provider
provider "aws" {
  region              = "${var.region}"
  allowed_account_ids = ["${var.aws-account}"]
}

// optional, comment out if not used
terraform {
  backend "s3" {
    region = "region"                                // CHANGE_IT
    bucket = "bucket name"                           // CHANGE_IT
    key    = "state/op-scim-application-env.tfstate"

    encrypt = "true"
    acl     = "bucket-owner-full-control"
  }
}
