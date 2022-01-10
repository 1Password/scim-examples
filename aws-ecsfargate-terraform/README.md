# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This guide will run you through a deployment of the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service (ECS) Fargate using Terraform. 

Note that due to the highly advanced and customizable nature of Fargate, this is only a suggested starting point. You may modify it to your needs to fit within your existing infrastructure.

## Prerequisites

Before beginning, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

- the [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) command line tools
- `scimsession` file and bearer token (as seen in `PREPARATION.md`)
- (Optional) DNS Zone in Route53

## Log In With `aws`

Ensure you are authenticated with the `aws` tool in your local environment.

See [Terraform AWS Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for more details.

## Configuration

### Copy Configuration

Copy `terraform.tfvars.template` to `terraform.tfvars`:

```bash
cp terraform.tfvars.template terraform.tfvars
```

### Copy `scimsession` File

Copy the `scimsession` file in the terraform code directory:

```bash
cp /path/to/scimsession ./
```

This will install the `scimsession` file automatically in your instance.

NOTE: If you skip this step or the installation of the `scimsession` file is not successful, you can perform this step manually afterwards. Ensure you `base64` encode the `scimsession` file, and store it in a secret as plain text (not in json, and not wrapped in quotation marks).

```bash
# only required if the automatic installation of the 'scimession' file is not successful
cat /path/to/scimsession | base64
# copy the output to Secrets Manager
```

### (Optional) Region

Create a region entry in `terraform.tfvars` for what region you're deploying in (default is `us-east-1`).

### Domain Name

This example uses AWS Certificate Manager to manage the certificate. Save the full domain name you want to use as domain_name in `terraform.tfvars`:

```
    domain_name = "scim-bridge.yourcompany.com"
```

### Route53 

If you use Route53, save the Route53 zone ID in the `terraform.tfvars`:

```
    dns_zone_id = "EXAMPLE123"
```

If you are not using Route53, you will need to comment out or remove the last section of the terraform.tf file that creates the route53 entry (below the comment) and remove `certificate_arn   = aws_acm_certificate_validation.scim_bridge_cert_validate.certificate_arn` and replace it with `certificate_arn   = aws_acm_certificate.scim_bridge_cert.arn`.

## Deploy

Run the following commands to create the necessary configuration settings:

```bash
terraform init
terraform plan -out=./op-scim.plan
```

You will now be asked to validate your configuration. Once you are sure it is correct, run the following:

```bash
terraform apply ./op-scim.plan
```

NOTE: If you are using something other than Route53 for your DNS, create a CNAME record pointing to the `loadbalancer-dns-name` that was printed out from `terraform apply`.

After a few minutes and the DNS update has had time to take effect, go to the SCIM Bridge URL you set, and you should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Complete Setup

Connect to your Identity Provider following [the remainder of our setup guide](https://support.1password.com/scim/#step-2-deploy-the-scim-bridge).

## Updating

To update your deployment to the latest version, edit the `task-definitions/scim.json` file and edit the following line:

```json
    "image": "1password/scim:v2.0.x",
```

Change `v2.0.x` to the latest version [seen here](https://app-updates.agilebits.com/product_history/SCIM).

Then, reapply your Terraform settings:

```bash
terraform plan -out=./op-scim.plan
terraform apply ./op-scim.plan
```

### December 2021 Update Changes

As of December 2021, [the ALB health check path has changed](https://github.com/1Password/scim-examples/pull/162). If you are updating from a version earlier than 2.3.0, edit your `terraform.tf` file [to use `/app` instead of `/`](https://github.com/1Password/scim-examples/pull/162/commits/a876c46b9812e96f65e42e0441a772566ca32176#) for the health check before reapplying your Terraform settings.

## Troubleshooting

### Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch -> Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `scim-bridge` and `redis` for your logs in this section.

### Specific Issues

#### Prompted to Sign In

If you browse to the domain name of your SCIM bridge and are met with a `Sign In With 1Password` link, this means the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** to complete the setup of your SCIM bridge.

To fix this, be sure to retry the instructions of Step 2 of Configuration. You will also need to restart your `scim-bridge` task in order for the changes to take effect when you update the `scimsession` secret.
