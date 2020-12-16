# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This document describes deploying the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service using Terraform.

Prerequisites
- DNS Zone
- scimsession file and bearer token

1. base64url encode your scimsession file and upload it to AWS Secret Manager. Take the arn and save it in terraform.tfvars with the name secret_arn.

2. Create or choose the zone you want to use and grab the zone id and save it as dns_zone_id in terraform.tfvars. Save the full domain name you want to use as domain_name in terraform.tfvars. 

3. Create the AWS Log Group in CloudWatch where you would like the logs to go. Save the name in terraform.tfvars as aws_logs_group.

4. Create a region entry in terraform.tfvars for what region you're deploying in. You can omit this if you are using us-east-1.

Your terraform.tfvars file should look something like this: 
domain_name = "scim-bridge.yourcompany.com"
dns_zone_id = "RANDOMLETTERS123"
secret_arn = "arn:aws:secretsmanager:<region>:<account-id>:secret:<secret-name>-BLAH"
aws_logs_group = "/ecs/scim-bridge"

Now run the following commands:
terraform apply -target=aws_acm_certificate.scim_bridge_cert
terraform apply