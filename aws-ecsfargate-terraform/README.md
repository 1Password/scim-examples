# Deploy 1Password SCIM Bridge on AWS Fargate with Terraform

*Learn how to deploy 1Password SCIM Bridge on AWS Fargate using Terraform.*

> **Note**
>
> Due to the highly advanced and customizable nature of Amazon Web Services, this is only a suggested starting point. You can modify it to fit your existing infrastructure.

**Table of contents:**

- [Before you begin](#before-you-begin)
- [Step 1: Configure the deployment](#step-1-configure-the-deployment)
- [Step 2: Deploy 1Password SCIM Bridge](#step-2-deploy-1password-scim-bridge)
- [Step 3: Connect your identity provider](#step-3-connect-your-identity-provider)
- [Update your SCIM Bridge](#update-your-scim-bridge)
- [Troubleshooting](#troubleshooting)

## Before you begin

Before you begin, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there. Then:

- Install [Terraform](https://www.terraform.io/downloads).
- Have your `scimsession` file and bearer token (as seen in [PREPARATION.md](/PREPARATION.md)) ready.
- Make sure you're authenticated with the `aws` command-line tool in your local environment. Learn more in the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

## Step 1: Configure the deployment

### Copy configuration template

Copy `terraform.tfvars.template` to `terraform.tfvars`:

```bash
cp terraform.tfvars.template terraform.tfvars
```

<details>
  <summary>Integrate with Google Workspace</summary>
<br />
Additional configuration is required to integrate 1Password with Google Workspace.

1. [Create a service account, key, and API client.](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client)
2. Save the Google Workspace service account key to the working directory.
3. Make sure the service account key is named `workspace-credentials.json`.
4. Uncomment the following line in `terraform.tfvars` and and enter the email address for the Google Workspace administrator associated with the credentials you just created.

```terraform
google_workspace_actor = "workspace.admin@example.com"
```

</details>

### 1.1: Copy `scimsession` file

Save the `scimsession` file from the automated user provisioning setup to the working directory. The Terraform plan will automatically create an AWS secret containing the contents of the `scimsession` file.

### 1.2: Set the region

Set the `aws_region` variable in `terraform.tfvars` to the AWS region you're deploying in (the default is `us-east-1`).

### 1.3: Set the domain name

This example uses AWS Certificate Manager to manage the required TLS certificate. Save the full domain name you want to use as `domain_name` in `terraform.tfvars`:

```terraform
domain_name = "<scim.example.com>"
```

<details>
  <summary>Optional: Configure additional features</summary>

### 1.4: Use an existing ACM wildcard certificate

If you would like to use an existing wildcard certificate in AWS Certificate Manager (`*.example.com`), uncommment this line in `terraform.tfvars`:

```terraform
wildcard_cert = true
```

### 1.5: External DNS

This deployment example uses Route 53 to create the required DNS record by default. If you are using another DNS provider, uncommment this line in `terraform.tfvars`:

```terraform
using_route53 = false
```

Create a CNAME record pointing to the `loadbalancer-dns-name` output printed out from `terraform apply`.

### 1.6: Use an existing VPC

This deployment example uses the default VPC for your AWS region. If you would like to specify another VPC to use instead, set the value in the `vpc_name` in `terraform.tfvars`:

```terraform
vpc_name           = "<name_of_VPC>"
```

### 1.7: Specify a name prefix

If you'd like to specify a common prefix for naming all supported AWS resources created by Terraform, set the value in the `name_prefix` variable in `terraform.tfvars`:

```terraform
name_prefix        = "<prefix>"
```

### 1.8: Set a log retention period

The deployment example retains logs indefinitely by default. If you'd like to set a different retention period, specify a number of days in the `log_retention_days` variable in `terraform.tfvars`:

```terraform
log_retention_days = <number_of_days>

```

### 1.9: Apply additional tags

To apply additional tags to all supported AWS resources created by Terraform, add keys and values to the `tags` variable in `terraform.tfvars`:

```terraform
tags = {
  <key1> = "<some_value>"
  <key2> = "<some_value>"
  …
}
```

</details>

## Step 2: Deploy 1Password SCIM Bridge

Run the following commands to create the necessary configuration settings:

```bash
terraform init
terraform plan -out="./op-scim.plan"
```

You'll be asked to validate your configuration. Check it to make sure it's correct, then run the following to deploy the SCIM bridge:

```bash
terraform apply "./op-scim.plan"
```

After a few minutes, and once the DNS has updated, go to the SCIM Bridge URL you set. You should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Step 3: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

---

## Update your SCIM Bridge

👍 Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://app-updates.agilebits.com/product_history/SCIM).

To update your SCIM bridge:

1. Update any variables and task definitions.
2. Create a plan for Terraform to apply.
3. Apply the new plan to your infrastructure.

The `terraform` CLI will output the details of the plan in addition to saving it to an output file (`op-scim.plan`). The plan will contain the steps necessary to bring your deployment in line with the latest configuration depending on the changes that are detected. Feel free to inspect the output to get a better idea of the steps that will be taken.

Below you can learn about some common update scenarios.

### Update to the latest tag version

To update your deployment to the latest version, edit the `task-definitions/scim.json` file and edit the following line:

```json
    "image": "1password/scim:v2.x.x",
```

Change `v2.x.x` to the latest version [found on the SCIM bridge release notes page](https://app-updates.agilebits.com/product_history/SCIM).

Then reapply your Terraform settings:

```bash
terraform plan -out="./op-scim.plan"
terraform apply "./op-scim.plan"
```

### Update to the latest configuration

There may be situations where you want to update your deployment with the latest configuration changes available in this repository even if you are already on the latest `1password/scim` tag. The steps are fairly similar to updating the tag, with a few minor differences:

1. [Optional] Verify that your Terraform variables (`./terraform.tfvars`) are correct and up to date.
2. [Optional] Reconcile the state between what Terraform knows about and your deployed infrastructure: `terraform refresh`.
3. Create an update plan to apply: `terraform plan -out="./op-scim.plan"`
4. Apply the plan to your infrastructure: `terraform apply "./op-scim.plan"`
5. Verify that there are no errors in the output as Terraform updates your infrastructure.

### Resource recommendations

The default resource recommendations for 1Password SCIM Bridge and Redis deployments are acceptable in most scenarios, but they fall short in high-volume deployments where there's a large number of users and/or groups.

Our current default resource requirements (defined in [scim.json](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/task-definitions/scim.json#L5)) are:

```yaml
  cpu: 128
  memory: 512
```

The following are recommendations for high-volume deployments:

```yaml
  cpu: 512
  memory: 1024
```

This recommendation is 4x the CPU and 2x the memory of the default values.

If you need help with the configuration, [contact 1Password Support](https://support.1password.com/contact/).

## Troubleshooting

### Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch > Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `op_scim_bridge` and `redis` for your logs in this section.

### Specific issues

#### If you're prompted to sign in

If you open your SCIM bridge domain in a browser and see a `Sign In With 1Password` button, the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** to complete the setup of your SCIM bridge.

To fix this, [copy the `scimsession` file](#11-copy-scimsession-file) again and stop the ECS task for your SCIM bridge. The ECS service will ensure that the task is restarted to reboot your SCIM bridge and apply the changes.
