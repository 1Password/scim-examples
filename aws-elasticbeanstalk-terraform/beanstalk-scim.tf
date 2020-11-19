terraform {
  required_version = "> 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}


# https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/archive_file
data "archive_file" "env" {
  type        = "zip"
  output_path = "${path.module}/file_to_upload/env.zip"

  source {
    content  = file("${path.module}/docker-compose.yml")
    filename = "docker-compose.yml"
  }

  source {
    content  = file("${path.module}/scimsession")
    filename = "scimsession"
  }
}

## We generate a ssh key to be able to connect directly to the machine
## and debug it! you can also use your already existing ssh keys for this.
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "1password-scimbridge-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "public_key" {
    content     = tls_private_key.ssh_key.public_key_openssh
    filename = "${path.module}/keys/id_rsa.pub"
}

resource "local_file" "private_key" {
    sensitive_content     = tls_private_key.ssh_key.private_key_pem
    file_permission = "0400"
    filename = "${path.module}/keys/id_rsa.pem"
}

## We generate a random s3-bucket suffix, this is to avoid collisions since AWS 
## s3 buckets are "global" to AWS, you can also use your own bucket name and
## remove this randomness alltogether
resource "random_pet" "bucket_suffix" {}

## AWS S3 Bucket
## Elastic beanstalk requires a S3 Bucket to host configuration files
resource "aws_s3_bucket" "beanstalk_scim" {
  bucket = "1password-scim-${random_pet.bucket_suffix.id}"
  acl    = "private"
}

resource "aws_s3_bucket_object" "env" {
  bucket = aws_s3_bucket.beanstalk_scim.bucket
  key    = "scim-1.6/env.zip"
  source = data.archive_file.env.output_path
  etag   = data.archive_file.env.output_md5
}

resource "aws_elastic_beanstalk_application" "onepassword_scimbridge" {
  name        = "1password-scimbridge"
  description = "1Password SCIM bridge"
}

resource "aws_elastic_beanstalk_application_version" "v1_6_test" {
  name        = "scim_1_6_test4"
  application = aws_elastic_beanstalk_application.onepassword_scimbridge.name
  description = "Version 1.6_test of app ${aws_elastic_beanstalk_application.onepassword_scimbridge.name}"
  bucket      = aws_s3_bucket.beanstalk_scim.bucket
  key         = aws_s3_bucket_object.env.key
}

resource "aws_elastic_beanstalk_application_version" "v1_6" {
  name        = "scim_1_6"
  application = aws_elastic_beanstalk_application.onepassword_scimbridge.name
  description = "Version 1.6 of app ${aws_elastic_beanstalk_application.onepassword_scimbridge.name}"
  bucket      = aws_s3_bucket.beanstalk_scim.bucket
  key         = aws_s3_bucket_object.env.key
}

# Beanstalk instance profile
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "in_beanstalk_ec2" {
  name               = "1p-scimbridge-beanstalk-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "in_beanstalk_ec2" {
  name = "1p-scimbridge-beanstalk-ec2-user"
  role = aws_iam_role.in_beanstalk_ec2.name
}

resource "aws_elastic_beanstalk_environment" "onepassword_scimbridge" {
  name         = "1password-scimbridge"
  application  = aws_elastic_beanstalk_application.onepassword_scimbridge.name
  cname_prefix = "1password-scim-${random_pet.bucket_suffix.id}"

  # To get the list of available solutions stack, aws-cli
  # aws elasticbeanstalk list-available-solution-stacks
  solution_stack_name = "64bit Amazon Linux 2 v3.2.0 running Docker"
  # solution_stack_name = "64bit Amazon Linux 2018.03 v2.22.1 running Multi-container Docker 19.03.6-ce (Generic)"
  version_label = aws_elastic_beanstalk_application_version.v1_6_test.name

  # There are a LOT of settings, see here for the basic list:
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.in_beanstalk_ec2.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "network"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:https"
    name      = "Port"
    value     = "443"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "TCP"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "DefaultProcess"
    value     = "https"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OP_LETSENCRYPT_DOMAIN"
    value     = local.OP_LETSENCRYPT_DOMAIN
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = aws_key_pair.ssh_key.key_name
  }
}
