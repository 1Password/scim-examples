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

<details>
  <summary>Optional: For customers using Google Workspace</summary>

### Copy Google Worskpace credentials

Copy the `workspace-settings.json` template file to this Terraform code directory:

```bash
cp ../beta/workspace-settings.json ./workspace-settings.json
```
Edit this file and add the respective values for each variable (see our [Google Workspace documentation](https://support.1password.com/scim-google-workspace/)).

Copy your `workspace-credentials.json` file to this Terraform code directory:

```bash
cp <path>/workspace-credentials.json ./workspace-credentials.json
```

### Enable Google Workspace configuration

Uncommment this line in `terraform.tfvars`:

```terraform
using_google_workspace = true
```

</details>

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

```terraform
domain_name = "<scim.example.com>"
```

<details>
  <summary>Optional: Configure additional features</summary>


### Use an existing ACM wildcard certificate

If you would like to use an existing wildcard certificate in AWS Certificate Manager (`*.example.com`), uncommment this line in `terraform.tfvars`:

```terraform
wildcard_cert = true
```

### External DNS 

This deployment example uses Route 53 to create the required DNS record by default. If you are using another DNS provider, uncommment this line in `terraform.tfvars`:

```terraform
using_route53 = false
```

Create a CNAME record pointing to the `loadbalancer-dns-name` output printed out from `terraform apply`.

### Use an existing VPC

This deployment example uses the default VPC for your AWS region. If you would like to specify another VPC to use instead, set the value in the `vpc_name` in `terraform.tfvars`:

```terraform
vpc_name           = "<name_of_VPC>"
```

### Specify a name prefix

If you would like to specify a common prefix for naming all supported AWS resources created by Terraform, set the value in the `name_prefix` variable in `terraform.tfvars`:

```terraform
name_prefix        = "<prefix>"
```

### Set a log retention period

Thw deployment example retains logs indifnietely by default. If you would like to set a differnet retention period, specify a number of days in the `log_retention_days` variable in `terraform.tfvars`:

```terraform
log_retention_days = <number_of_days>

```

### Apply additional tags

To apply additional tags to all supported AWS resources created by Terraform, add keys and values to the `tags` variable in `terraform.tfvars`:

```terraform
tags = {
  <key1> = "<some_value>"
  <key2> = "<some_value>"
  …
}
```

</details>

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

The process for updating your infrastructure involes a few key steps. Lucky for us most of the heavy lifting is done by the `terraform` CLI.

The update steps are generally as follows:

1. Update any variables and task definitions as necessary
2. Create a plan for Terraform to apply
3. Apply the new plan to your infrastrucure

Note that the `terraform` CLI will output the details of the plan in addition to saving it to an output file (`./op-scim.plan`). The plan will contain the steps necessary to bring your deployment in line with the latest configuration depending on the changes that are detected. Feel free to inspect the output to get a better idea of the steps that will be taken.

Below we go into detail about some common reasons that you would want to update your infrastructure.

### Updating to the latest tag version

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

### Updating to the latest configuration

There may be situations where you want to update your deployment with the latest configuration changes available in this repository even if you are already on the latest `1password/scim` tag. The steps are fairly similar to updating the tag with a few minor differences.

Update steps:

1. [Optional] Verify that your Terraform variables (`./terraform.tfvars`) are correct and up to date
2. [Optional] Reconcile the state between what Terraform knows about and your deployed infrastructure: `terraform refresh`
3. Create an update plan to apply: `terraform plan -out=./op-scim.plan`
4. Apply the plan to your infrastructure: `terraform apply ./op-scim.plan`
5. Verify that there are no errors in the output as Terraform updates your infrastructure

### Resource Recommendations

The default resource recommendations for the SCIM bridge and Redis deployments are acceptable in most scenarios, but they fall short in high volume deployments where there is a large number of users and/or groups. 

Our current default resource requirements (defined in [scim.json](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/task-definitions/scim.json#L5)) are:

```yaml
  cpu: 128
  memory: 512
```

Proposed recommendations for high volume deployments:

```yaml
  cpu: 512
  memory: 1024
```

This proposal is 4x the CPU and 2x the memory of the default values.

Please reach out to our [support team](https://support.1password.com/contact/) if you need help with the configuration or to tweak the values for your deployment.

### April 2022 changes

As of April 2022 we have updated the Redis deployment to require a maximum of 512 MB of memory. This meant that we also had to bump required memory for the "op-scim-bridge" task definition to 1024 MB.

The Redis dataset maximum is set to 256Mb and an eviction policy will determine how keys are evicted when the maximum data set size is approached.

This should prevent Redis from consuming large amounts of memory and eventually running out of available memory. The SCIM bridge is also restarted in instances where Redis runs into an out of memory error.

### December 2021 changes

As of December 2021, [the ALB health check path has changed](https://github.com/1Password/scim-examples/pull/162). If you are updating from a version earlier than 2.3.0, edit your `terraform.tf` file [to use `/app` instead of `/`](https://github.com/1Password/scim-examples/pull/162/commits/a876c46b9812e96f65e42e0441a772566ca32176#) for the health check before reapplying your Terraform settings.

## Troubleshooting

### Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch -> Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `op_scim_bridge` and `redis` for your logs in this section.

### Specific issues

#### Prompted to Sign In

If you browse to the domain name of your SCIM bridge and are met with a `Sign In With 1Password` link, this means the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** to complete the setup of your SCIM bridge.

To fix this, be sure to retry [the instructions of Step 2 of Configuration](#copy-`scimsession`-file). You will also need to restart your `op_scim_bridge` task in order for the changes to take effect after you update the `scimsession` secret.
