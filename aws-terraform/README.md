# Deploying the 1Password SCIM Bridge in AWS/Terraform

This example describes one of the simplest methods of deploying the 1Password SCIM bridge to your Amazon Web Service cloud using Terraform.


## Preparing

Please ensure you've read through the [Preparing](https://github.com/1Password/scim-examples/tree/master/PREPARING.md) document before beginning deployment.


## Deployment overview

For most installations, one `t3.micro` size instance will be adequate to serve Identity Provider requests. Ensure instance performance is monitored, and upgrade instance size if required.

The minimum supported version of Terraform is `0.12.x`.

You'll also want the `terraform` command line tools package for your respective system.


### Optional Components

* **AWS Key Management Service and Secrets Manager** - KMS Key is used to encrypt/decrypt Secrets Manager data, for example, session file and must be configured prior to deploying your 1Password SCIM infrastructure. The SCIM bridge has to know where to find the session file, so please refer to its documentation on how to set that up.
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

1. Copy `deploy/example_env` to a new directory according to the established naming conventions. Example: `deploy/development`.

2. Upload encrypted session file to the AWS Secrets Manager (if required).

Example:
```bash
aws secretsmanager create-secret --name op-scim-dev/scimsession --secret-binary /path/to/scimsession --region <aws_region>
aws secretsmanager describe-secret --secret-id op-scim/scimsession --region <aws_region>
```
Custom KMS key can be specified by `--kms-key-id <kms_key_arn>`, in this case make sure deployed instances have access to that key, otherwise skip this option. If you don't specify key, then Secrets Manager defaults to using the AWS account's default Customer Master Key (CMK, the one named `aws/secretsmanager`).

3. Adjust `variables.tf`, `main.tf` and `providers.tf` as required.

4. Use `terraform` commands to deploy, verify, and troubleshoot.

Example:
```bash
  terraform init
  terraform plan -out=/tmp/op-scim.plan
  terraform apply /tmp/op-scim.plan
```

5. Update/Create 1Password SCIM endpoint configuration in your Identity Provider using your generated [Bearer Token](https://github.com/1Password/scim-examples/tree/master/PREPARING.md).


## Advanced

### Logging

All logs go to `syslog` (AWS EC2 instance OS). You may consider configuring a "bastion" host or AWS System Manager or assign Public IP address to your instance, in order to be able to login to the deployed EC2 instance to view system logs.


### Destroying and Redeploying

You can destroy and redeploy the instance whenever you feel the need to. No permanent data is stored within the SCIM bridge. This is useful for upgrading your SCIM bridge with important bugfix or feature releases.

`terraform destroy` (if target is not specified) deletes all but the `scimsession` file in Secrets Manager (deployed separately).


### Debian Package

The 1Password SCIM Bridge is distributed as a Debian package and installed automatically during the deployment process. The following commands are included in the AWS EC2 instance user-data:

```bash
- curl -L https://apt.agilebits.com/gpg.key 2> /dev/null | apt-key add -
- echo '${SCIM_REPO}' > /etc/apt/sources.list.d/op-scimrepo.list
- apt-get -y -qq update && apt-get -y -qq install op-scim
- echo '10 * * * * root /usr/local/bin/op-scim-upgrade.sh 2>&1 | logger -t op-scim-deploy-cron' > /etc/cron.d/50_op-scim && chmod 0644 /etc/cron.d/50_op-scim
```
