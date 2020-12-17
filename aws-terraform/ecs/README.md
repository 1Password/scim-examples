# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This document describes deploying the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service Fargate using Terraform. It's just a suggested starting point - you may be using different services for different things, this example uses only AWS products. Please familiarize yourself with [Preparation.md](../../Preparation.md) before beginning.

Prerequisites
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
- DNS Zone in Route 53
- scimsession file and bearer token ([follow step 1 here](https://support.1password.com/scim/))
- an empty file `terraform.tfvars` in this directory

1. Have the scimsession file available in the same directory has the terraform code

2. Create or choose the zone you want to use and grab the Hosted zone ID and save it as dns_zone_id in terraform.tfvars. Save the full domain name you want to use as domain_name in terraform.tfvars.

3. Create a region entry in terraform.tfvars for what region you're deploying in. You can omit this if you are using us-east-1.

Your terraform.tfvars file should look something like this:
```
domain_name = "scim-bridge.yourcompany.com"
dns_zone_id = "RANDOMLETTERS123"
```

Now run the following commands:
```
terraform init
terraform apply -target=aws_acm_certificate.scim_bridge_cert
terraform plan -out=./op-scim.plan
# Validate what this plan does by reading it
terraform apply ./op-scim.plan
```

After a few minutes, if you go to the SCIM Bridge URL you set, you should be able to enter your bearer token to verify that your scim bridge is up and running. Connect to your IdP using step 3 [here](https://support.1password.com/scim/) and go to your 1Password account and check that provisioning is on in Setting -> Provisioning and you should be good to go!