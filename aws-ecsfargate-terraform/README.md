# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This document describes deploying the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service Fargate using Terraform. It's just a suggested starting point - you may be using different services for different things, this example uses only AWS products. Please familiarize yourself with [PREPARATION.md](/PREPARATION.md) before beginning.

Prerequisites
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- AWS credentials configured (either through $HOME/.aws/credentials or environment variable)
  see: [Terraform AWS authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
- (Optional) DNS Zone in Route 53
- scimsession file and bearer token ([follow step 1 here](https://support.1password.com/scim/))

1. Copy `terraform.tfvars.template` to `terraform.tfvars`

2. Copy the `scimsession` file in the terraform code directory

3. (Optional) If you use route 53, save the Route53 zone ID in the `terraform.tfvars`

4. Save the full domain name you want to use as domain_name in terraform.tfvars

5. Create a region entry in terraform.tfvars for what region you're deploying in. You can omit this if you are using us-east-1

Your terraform.tfvars file should look something like this:
```
domain_name = "scim-bridge.yourcompany.com"
dns_zone_id = "RANDOMLETTERS123"
```
Note: If you are not using Route53, you don't need to set the zone id and can remove that line from the tfvars file.

Now run the following commands (Note: If you are not using Route53 the second command is unnecessary):
```
terraform init
terraform plan -out=./op-scim.plan
# Validate what this plan does by reading it
terraform apply ./op-scim.plan
```
If you are using something other than Route53 for your domain name, point your domain to the `loadbalancer-dns-name` that was printed out from your terraform apply.

After a few minutes, if you go to the SCIM Bridge URL you set, you should be able to enter your bearer token to verify that your scim bridge is up and running. Connect to your IdP using step 3 [here](https://support.1password.com/scim/) and go to your 1Password account and check that provisioning is on in Setting -> Provisioning and you should be good to go!

If you want to check out the logs for your scim bridge, in AWS go to Cloudwatch -> Log Groups and you should see the log group that was printed out at the end of your terraform apply. You can then see the scim-bridge and redis container logs. 

Note: If you are using this as a guide but not running it exactly, ensure that you are `base64url` encoding the scimsession and storing it in a secret as plaintext (not json, not wrapped in quotation marks)
