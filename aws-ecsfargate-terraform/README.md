# Deploying the 1Password SCIM Bridge on AWS Fargate with Terraform

This guide will run you through a deployment of the 1Password SCIM bridge on AWS Fargate using Terraform. 

Note that due to the highly advanced and customizable nature of Amazon Web Services, this is only a suggested starting point. You may modify it to your needs to fit within your existing infrastructure.

## Prerequisites

Before beginning, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

- Install [Terraform](https://www.terraform.io/downloads)
- Have your `scimsession` file and bearer token (as seen in `PREPARATION.md`) ready

## Sign in with `aws`

Ensure you are authenticated with the `aws` tool in your local environment.

See [Terraform AWS Authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for more details.

## Configuration

### Copy configuration template

Copy `terraform.tfvars.template` to `terraform.tfvars`:

```bash
cp terraform.tfvars.template terraform.tfvars
```

### Copy `scimsession` file

Copy the `scimsession` file in the Terraform code directory:

```bash
cp <path>/scimsession ./
```

This will automatically create an AWS secret containing the contents of the `scimsession` file in your instance.

**Note:** If you skip this step or the installation of the scimsession file is not successful, you can create the required AWS secret manually. Ensure you `base64` encode the `scimsession` file, and store it in a secret as **plain text** (not as JSON, and not wrapped in quotation marks):

```bash
# only required if the automatic installation of the 'scimession' file is not successful
cat <path>/scimsession | base64
# copy the output to Secrets Manager
```

### Region

Set the `aws_region` variable in `terraform.tfvars` to the AWS region you're deploying in (the default is `us-east-1`).

### Domain name

This example uses AWS Certificate Manager to manage the required TLS certificate. Save the full domain name you want to use as `domain_name` in `terraform.tfvars`:

```
domain_name = "<scim.example.com>"
```

### (Optional) Use an existing ACM wildcard certificate

If you would like to use an existing wildcard certificate in AWS Certificate Manager (`*.example.com`), uncommment this line in `terraform.tfvars`:

```
wildcard_cert = true
```

### (Optional) External DNS 

This deployment example uses Route 53 to create the required DNS record. If you are using another DNS provider, uncommment this line in `terraform.tfvars`:

```
using_route53 = false
```

Create a CNAME record pointing to the `loadbalancer-dns-name` output printed out from `terraform apply`.

### (Optional) Use an existing VPC

This deployment example uses the default VPC for your AWS region. If you would like to specify another VPC to use instead, set the value in the `vpc_name` in `terraform.tfvars`:

```
vpc_name           = "<name_of_VPC>"
```

### (Optional) Specify a name prefix

If you would like to specify a common prefix for naming all supported AWS resources created by Terraform, set the value in the `name_prefix` variable in `terraform.tfvars`:

```
name_prefix        = "<prefix>"

```

### (Optional) Set a log retention period

Thw deployment example retains logs indifnietely by default. If you would like to set a differnet retention period, specify a number of days in the `log_retention_days` variable in `terraform.tfvars`:

```
log_retention_days = <number_of_days>

```

### (Optional) Apply additional tags

If you would apply additional tags to all supported AWS resources created by Terraform, add some to the `tags` variable in `terraform.tfvars`:

```
tags = {
  <key1> = "<some_value>"
  <key2> = "<some_value>"
  …
}
```

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

After a few minutes and the DNS update has had time to take effect, go to the SCIM Bridge URL you set, and you should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Complete setup

Connect to your Identity Provider following [the remainder of our setup guide](https://support.1password.com/scim/#step-2-deploy-the-scim-bridge).

## Updating

To update your deployment to the latest version, edit the `task-definitions/scim.json` file and edit the following line:

```json
    "image": "1password/scim:v2.x.x",
```

Change `v2.x.x` to the latest version [seen here](https://app-updates.agilebits.com/product_history/SCIM).

Then, reapply your Terraform settings:

```bash
terraform plan -out=./op-scim.plan
terraform apply ./op-scim.plan
```

### April 2022 changes

As of April 2022, we have [updated the Redis configuration to require a maximum of 512 MB of memory](https://github.com/1Password/scim-examples/pull/182). This meant that we also had to bump required memory for the `op-scim-bridge` task definition to 1024 MB.

Applying these changes to an existing 1Password SCIM bridge deployment will require adjusting the parameters of both [the task definition](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/task-definitions/scim.json) and [the main Terraform script](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/main.tf) as amended in [this PR](https://github.com/1Password/scim-examples/pull/182/files).

### December 2021 changes

As of December 2021, [the ALB health check path has changed](https://github.com/1Password/scim-examples/pull/162). If you are updating from a version earlier than 2.3.0, edit your `terraform.tf` file [to use `/app` instead of `/`](https://github.com/1Password/scim-examples/pull/162/commits/a876c46b9812e96f65e42e0441a772566ca32176#) for the health check before reapplying your Terraform settings.

## Troubleshooting

### Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch -> Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `op_scim_bridge` and `redis` for your logs in this section.

### Specific issues

#### Prompted to Sign In

If you browse to the domain name of your SCIM bridge and are met with a `Sign In With 1Password` link, this means the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** to complete the setup of your SCIM bridge.

To fix this, be sure to retry [the instructions of Step 2 of Configuration](#copy-`scimsession`-file). You will also need to restart your `op_scim_bridge` task in order for the changes to take effect after you update the `scimsession` secret.
