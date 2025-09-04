# Deploy 1Password SCIM Bridge on AWS Fargate with Terraform

_Learn how to deploy 1Password SCIM Bridge on AWS Fargate using Terraform._

> **Note**
>
> Due to the highly advanced and customizable nature of Amazon Web Services, this is only a suggested starting point. You can modify it to fit your existing infrastructure.

## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md). You'll also need to:

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

After a few minutes, and once the DNS has updated, go to the SCIM bridge URL you set. You should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Step 3: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

---

## Update your SCIM bridge

👍 Check for 1Password SCIM Bridge updates on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).

To update your SCIM bridge:

1. Update any variables and task definitions.
2. Create a plan for Terraform to apply.
3. Apply the new plan to your infrastructure.

The `terraform` CLI will output the details of the plan in addition to saving it to an output file (`op-scim.plan`). The plan will contain the steps necessary to bring your deployment in line with the latest configuration depending on the changes that are detected. Feel free to inspect the output to get a better idea of the steps that will be taken.

Below you can learn about some common update scenarios.

### Update to the latest tag version

To update your deployment to the latest version, edit the `task-definitions/scim.json` file and edit the following line:

```json
    "image": "1password/scim:v2.9.13",
```

Learn about the changes included in each version on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).

Then, reapply your Terraform settings:

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

The resource allocations for 1Password SCIM Bridge should be increased when provisioning a large number of users or groups. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | SCIM bridge CPU | SCIM bridge memory | Task CPU | Task memory |
| --------- | --------------- | --------------- | ------------------ | -------- | ----------- |
| Default   | <1,000          | 128             | 512                | 256      | 1024        |
| High      | 1,000–5,000     | 512             | 1024               | 1024     | 2048        |
| Very high | >5,000          | 1024            | 1024               | 2048     | 4096        |

If provisioning more than 1,000 users, the resources assigned to the container definition for 1Password SCIM Bridge should be updated as recommended in the above table. The resource allocation specified for the Redis container does not need to be adjusted. The task definition must also be updated to allocate enough resources for both containers. Fargate task resources are constrained by AWS; the recommended configurations are the minimum resources required for both containers (see [Fargate task definition considerations: Task CPU and memory](https://docs.aws.amazon.com/AmazonECS/latest/userguide/fargate-task-defs.html#fargate-tasks-size)).

Resources for the SCIM bridge container are declared in [`scim.json`](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/task-definitions/scim.json):

```json
[
  {
    "name": "op_scim_bridge",
    ...
    "cpu": 128,
    "memory": 512,
    ...
  },
  ...
]
```

Task CPU and memory allocations are configured in the ECS task definition resource in [`main.tf`](https://github.com/1Password/scim-examples/blob/master/aws-ecsfargate-terraform/main.tf):

```terraform
resource "aws_ecs_task_definition" "op_scim_bridge" {
  ...
  memory                   = 1024
  cpu                      = 256
  ...
}
```

If you need help with the configuration, [contact 1Password Support](https://support.1password.com/contact/).

## Customize Redis

As of SCIM bridge `v2.8.5`, additional Redis configuration options are available. `OP_REDIS_URL` must be unset for any of these environment variables to be read. These environment variables may be especially helpful if you need support for URL-unfriendly characters in your Redis credentials.

> **Note**  
> `OP_REDIS_URL` must be unset, otherwise the following environment variables will be ignored.

- `OP_REDIS_HOST`: overrides the default hostname of the redis server (default: `redis`). It can be either another hostname, or an IP address.
- `OP_REDIS_PORT`: overrides the default port of the redis server connection (default: `6379`).
- `OP_REDIS_USERNAME`: sets a username, if any, for the redis connection (default: `(null)`)
- `OP_REDIS_PASSWORD`: Sets a password, if any, for the redis connection (default: `(null)`). Can accommodate URL-unfriendly characters that `OP_REDIS_URL` may not accommodate.
- `OP_REDIS_ENABLE_SSL`: Optionally enforce SSL on redis server connections (default: `false`). (Boolean `0` or `1`)
- `OP_REDIS_INSECURE_SSL`: Set whether to allow insecure SSL on redis server connections when `OP_REDIS_ENABLE_SSL` is set to `true`. This may be useful for testing or self-signed environments (default: `false`) (Boolean `0` or `1`).

To apply these customizations, replace the following lines in [`scim.json`](./task-definitions/scim.json):

```
{
  "name": "OP_REDIS_URL",
  "value": "redis://localhost:6379"
},
```

with the desired environment variables and their values, e.g.,:

```
{
  "name": "OP_REDIS_HOST",
  "value": "hostname"
},
{
  "name": "OP_REDIS_PORT",
  "value": "6379"
},
{
  "name": "OP_REDIS_USERNAME",
  "value": "op-redis-admin"
},
{
  "name": "OP_REDIS_PASSWORD",
  "value": "apv.zbu8wva8gwd1EFC-fake.password"
},
{
  "name": "OP_REDIS_ENABLE_SSL",
  "value": "1"
},
```

## Troubleshooting

### Logs

If you want to view the logs for your SCIM bridge within AWS, go to **Cloudwatch > Log Groups** and you should see the log group that was printed out at the end of your `terraform apply`. Look for `op_scim_bridge` and `redis` for your logs in this section.

### Specific issues

#### If you're prompted to sign in

If you open your SCIM bridge domain in a browser and see a `Sign In With 1Password` button, the `scimsession` file was not properly installed. Due to the nature of the ECS deployment, **this “sign in” option cannot be used** to complete the setup of your SCIM bridge.

To fix this, [copy the `scimsession` file](#11-copy-scimsession-file) again and stop the ECS task for your SCIM bridge. The ECS service will ensure that the task is restarted to reboot your SCIM bridge and apply the changes.

#### If you can't access AWS Secrets Manager

Because the `aws_security_group.service` resource creates a security group that restricts outbound traffic from the Fargate task, 1Password SCIM Bridge may only connect to the 1Password service over HTTPS on this port. If the VPC where the Fargate task is deployed hasn't been configured to support DNS resolution through the Amazon DNS server, this security group will also restrict DNS resolution.

**_Example error:_**

> ```sh
> ResourceInitializationError: unable to pull secrets or registry auth: execution resource retrieval failed: unable to retrieve secret from asm: service call has been retried 5 time(s): failed to fetch secret arn:aws:secretsmanager:us-east-1:…:secret:op-scim-bridge-sercretARN from secrets manager: RequestCanceled: request context canceled caused by: context deadline exceeded. Please check your task network configuration.
> ```

To resolve this issue, enable the Amazon DNS server for the VPC where your SCIM bridge is deployed. See Learn more in the [view and update DNS attributes for your VPC documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html#vpc-dns-updating). Select Enable for at least "DNS resolution" to resolve this.

Alternatively, add an additional block to to the `aws_security_group.service` resource in `main.tf` to create a security group rule that enables DNS resolution. For example:

```terraform
  # Allow DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
```
