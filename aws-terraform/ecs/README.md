# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This document describes deploying the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service Fargate using Terraform. It's just a suggested starting point - you may be using different services for different things, this example uses only AWS products. Please familiarize yourself with [Preparation.md](../../Preparation.md) before beginning.

Prerequisites
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed and configured
- DNS Zone in Route 53
- scimsession file and bearer token ([follow step 1 here](https://support.1password.com/scim/))
- an empty file `terraform.tfvars` in this directory

1. Base64url encode your scimsession file (a command one could use on a mac is `cat /local/path/to/scimsession | base64 | tr -d "\n"`) and upload it to AWS Secret Manager. Take the arn and save it in terraform.tfvars with the name secret_arn. (Some details about this can be found [here](https://aws.amazon.com/premiumsupport/knowledge-center/ecs-data-security-container-task/))

2. Create or choose the zone you want to use and grab the Hosted zone ID and save it as dns_zone_id in terraform.tfvars. Save the full domain name you want to use as domain_name in terraform.tfvars.

3. Create the [AWS Log Group](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html) in CloudWatch where you would like the logs to go. Save the name in terraform.tfvars as aws_logs_group.

4. Create a region entry in terraform.tfvars for what region you're deploying in. You can omit this if you are using us-east-1.

Your terraform.tfvars file should look something like this:
```
domain_name = "scim-bridge.yourcompany.com"
dns_zone_id = "RANDOMLETTERS123"
secret_arn = "arn:aws:secretsmanager:<region>:<account-id>:secret:<secret-name>-BLAH"
aws_logs_group = "/ecs/scim-bridge"
```

Now run the following commands:
```
terraform init
terraform apply -target=aws_acm_certificate.scim_bridge_cert
terraform plan -out=./op-scim.plan
terraform apply ./op-scim.plan
```

After a few minutes, if you go to the SCIM Bridge URL you set, you should be able to enter your bearer token to verify that your scim bridge is up and running. Connect to your IdP using step 3 [here](https://support.1password.com/scim/) and go to your 1Password account and check that provisioning is on in Setting -> Provisioning and you should be good to go!