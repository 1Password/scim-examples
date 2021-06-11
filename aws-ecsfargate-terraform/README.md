# Deploying the 1Password SCIM Bridge in AWS ECS with Terraform

This guide will run you through a deployment of the 1Password SCIM bridge to your Amazon Web Service Elastic Container Service (ECS) Fargate using Terraform. 

Note that due to the highly advanced and customizable nature of Fargate, this is only a suggested starting point. You may modify it to your needs to fit within your existing infrastructure.

# Prerequisites

Before beginning, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

- the [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) command line tools
- `scimsession` file and bearer token (as seen in `PREPARATION.md`)
- (Optional) DNS Zone in Route53

## Log In With `aws`

Ensure you are authenticated with the `aws` tool in your local environment.

See [Terraform AWS Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for more details.

## Configuration

1. Copy `terraform.tfvars.template` to `terraform.tfvars`:

```bash
cp terraform.tfvars.template terraform.tfvars
```

2. Copy the `scimsession` file in the terraform code directory:

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

3. Create a region entry in `terraform.tfvars` for what region you're deploying in (default is `us-east-1`).

4. (Optional) Save the full domain name you want to use as domain_name in `terraform.tfvars`:

With the SCIM bridge, you have two options for securing it with TLS:

* Allowing the SCIM bridge to use the complimentary Let’s Encrypt service to receive one
* Using AWS’s Certificate Manager service

If you are _not_ using Certificate Manager, be sure to set the domain below.

Otherwise, if you _are_ using Certificate Manager, you can skip this step.

```
domain_name = "scim-bridge.yourcompany.com"
```

5. (Optional) If you use Route53, save the Route53 zone ID in the `terraform.tfvars`:

```
dns_zone_id = "EXAMPLE123"
```

## Deploy

```bash
terraform init
terraform plan -out=./op-scim.plan
```

You will now be asked to validate your configuration. Once you are sure it is correct, run the following:

```bash
terraform apply ./op-scim.plan
```

NOTE: If you are using something other than Route53 for your domain name, point your domain to the `loadbalancer-dns-name` that was printed out from `terraform apply`.

After a few minutes and the DNS update has had time to take effect, go to the SCIM Bridge URL you set, and you should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Complete Setup

Connect to your Identity Provider following [the remainder of our setup guide](https://support.1password.com/scim/#step-2-deploy-the-scim-bridge).

## Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch -> Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `scim-bridge` and `redis` for your logs in this section.

## Troubleshooting

If you browse to the domain name of your SCIM bridge and are met with a `Sign In With 1Password` link, this means the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** complete the setup of your SCIM bridge.

To fix this, be sure to retry the instructions of Step 2 of Configuration. You will also need to restart your `scim-bridge` task in order for the changes to take effect when you update the `scimsession` secret.
