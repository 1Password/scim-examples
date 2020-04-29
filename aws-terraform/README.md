# Deploying the 1Password SCIM Bridge in AWS/Terraform

This example describes one of the simplest methods of deploying the 1Password SCIM bridge to your Amazon Web Service cloud using Terraform.


## Preparing

Please ensure you've read through [PREPARING.md](https://github.com/1Password/scim-examples/tree/master/PREPARING.md) before beginning deployment.


## Deployment overview

### Required Tools 

The minimum supported version of Terraform is `0.12.x`.

You'll also want the `terraform` command line tools package for your operating system.


### Instance Size

For most installations, one `t3.micro` size instance will be adequate to serve Identity Provider requests. We recommend enabling auto-scaling, but it is not strictly necessary.


### Optional Components

* **AWS Key Management Service and Secrets Manager** - Key Management Service (KMS) key is used to encrypt/decrypt Secrets Manager data. `scimsession` file must be placed into the service prior to deploying your 1Password SCIM Bridge while using this service. Additionally, the SCIM Bridge has to know where to find the `scimsession` file, so please refer to the KMS/SM documentation on how to set that up.
* **AWS S3 Bucket** - This can be used to store the terraform state file, load balancer logs, and so on.


## Code Structure

Below is the overall code structure of the Terraform deployment.

- `deploy` - directory contains deployments/environments and separates them from each other. Example: `development`, `staging`, `testing` and so on.
    - `variables.tf` - sets global variables for the specific deployment and provider configuration. This file already has default values for some of the variables, but it is recommended to review all of them.
    - `providers.tf` - AWS and Terraform provider configuration.
    - `main.tf` - invokes required modules and sets module specific variables.
    - `output.tf` - prints out some of the resources and values.
    - `deploy/<new-environment>/user_data/03-default-users.yml` - user configuration, ssh username and key.
    - `new-environment` - can be created by copying an existing one to a new directory and adjusting `variables.tf`, `main.tf`, `providers.tf` as required.
    - `module_scim_app` - deploys the following AWS resources and their dependencies: Application Load Balancer (ALB), Auto Scaling Groups (ASG), Identity and Access Management (IAM), instance and load balancer security groups, and a public DNS record. ASG monitors instances and automatically adjusts capacity to maintain steady, predictable performance. Capacity is configured in `main.tf` and instance specific configuration is in `variables.tf`.
    - `module_scim_infra` - deploys network infrastructure: Virtual Private Cloud, networking (route tables, etc), Route 53, Internet Gateways, NAT Gateways, and their dependencies.


## Deploying using Terraform

1. Copy `deploy/example_env` to a new directory according to your established naming conventions. Example: `deploy/development`.

2. Upload encrypted session file to the AWS Secrets Manager (if required).

Example:
```bash
aws secretsmanager create-secret --name op-scim-dev/scimsession --secret-binary /path/to/scimsession --region <aws_region>
aws secretsmanager describe-secret --secret-id op-scim/scimsession --region <aws_region>
```
Custom Key Management Service key can be specified by `--kms-key-id <kms_key_arn>`. Ensure deployed instances have access to that key. If you don't specify key, then Secrets Manager defaults to using the AWS account's default Customer Master Key (CMK, the one named `aws/secretsmanager`).

3. Adjust `variables.tf`, `main.tf` and `providers.tf` as required.

4. Use `terraform` commands to deploy and verify your installation.

Example:
```bash
  terraform init
  terraform plan -out=./op-scim.plan
  terraform apply ./op-scim.plan
```

5. Update/Create 1Password SCIM endpoint configuration in your Identity Provider using your generated [bearer token](https://github.com/1Password/scim-examples/tree/master/PREPARING.md).


## Advanced

### Logging

All logs go to `syslog` (AWS EC2 instance OS). You can use the AWS System Manager to view logs for your instance.


### Upgrading and Redeployment

You can destroy and redeploy the instance whenever you feel the need to. No permanent data is stored within the SCIM bridge. This is useful for upgrading your SCIM bridge with important bugfix or feature releases.

`terraform destroy` deletes all but the `scimsession` file in Secrets Manager (deployed separately).


### Debian Package

The 1Password SCIM Bridge is distributed as a Debian package and installed automatically during the deployment process. The following commands are included in the AWS EC2 instance user-data:

```bash
- curl -L https://apt.agilebits.com/gpg.key 2> /dev/null | apt-key add -
- echo '${SCIM_REPO}' > /etc/apt/sources.list.d/op-scimrepo.list
- apt-get -y -qq update && apt-get -y -qq install op-scim
- echo '10 * * * * root /usr/local/bin/op-scim-upgrade.sh 2>&1 | logger -t op-scim-deploy-cron' > /etc/cron.d/50_op-scim && chmod 0644 /etc/cron.d/50_op-scim
```
