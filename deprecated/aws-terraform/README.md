# Deploying the 1Password SCIM bridge in AWS/Terraform

This document describes deploying the 1Password SCIM bridge to your Amazon Web Service cloud services using Terraform.

**NOTE** This deployment has been deprecated in favour of the [aws-ecsfargate-terraform](../aws-ecsfargate-terraform) deployment.

## Preparing

This is only an example of how you could deploy the 1Password SCIM bridge to your existing AWS infrastructure. As an advanced form of deployment, this AWS/Terraform example can be integrated into your existing infrastructure. Feel free to modify the deployment to suit your specific needs.

If you find that you are not using a majority of the services listed in this documentation within your AWS account - for instance, you have an external DNS provider, or you are providing your own certificates through a third-party service - consider deploying through [Kubernetes](https://github.com/1Password/scim-examples/tree/master/kubernetes/README.md) using AWS Elastic Kubernetes Service (EKS). The 1Password SCIM bridge is not a resource-intensive service, and a full AWS deployment may include more infrastructure than you require, unless it fits neatly into your existing setup.

To continue, please ensure you've read through [PREPARATION.md](../PREPARATION.md) before beginning deployment.

## Deployment overview

### Required Tools

The minimum supported version of Terraform is `0.12.x`.

You will also want to ensure the `aws` and `terraform` CLI tools are installed for your operating system.

### Instance Size

For most installations, one [t3.micro](https://github.com/1Password/scim-examples/tree/master/aws-terraform/terraform/deploy/example_env/variables.tf#L96) size instance will be adequate to serve Identity Provider requests. We recommend enabling auto-scaling, but it is not strictly necessary.

### AWS Components

* **AWS Elastic Compute Cloud** - Elastic Compute Cloud (EC2) provides the compute necessary to deploy the SCIM bridge.
* **AWS Key Management Service and Secrets Manager** - Key Management Service (KMS) key is used to encrypt/decrypt Secrets Manager data. You’ll be placing the `scimsession` file (mentioned in [PREPARATION.md](/PREPARATION.md)) in the steps outlined here.
* **AWS S3 Bucket** - This can be used to store the terraform state file, load balancer logs, and so on.
* **AWS Certificate Manager** - Used to manage SSL certificates for your deployment.

## Code Structure

Below is the overall code structure of the Terraform deployment.

- `module_scim_app/` - deploys the following AWS resources and their dependencies: Application Load Balancer (ALB), Auto Scaling Groups (ASG), Identity and Access Management (IAM), instance and load balancer security groups, and a public DNS record.
- `module_scim_infra/` - deploys network infrastructure: Virtual Private Cloud, networking (route tables, etc), Route 53, Internet Gateways, NAT Gateways, and their dependencies.
- `deploy/` - where the deployment files are contained.
    - `{environment}/` - a directory named after the environment you’re deploying to.
        - `user_data/` - contains files related to the specific operating system setup within the container.
            - `01-set-hostname.yml` - hostname options for the OS.
            - `02-environment.yml` - environment variable setup.
            - `03-default-users.yml` - default user setup for the environment (modify if needed).
        - `variables.tf` - sets global variables for the specific deployment and provider configuration. This file already has default values for some of the variables, but it is recommended to review all of them.
        - `providers.tf` - AWS and Terraform provider configuration.
        - `main.tf` - invokes required modules and sets module specific variables.
        - `output.tf` - prints out some of the resources and values.


## Deploying using Terraform

0. Configure AWS tools by running the command `aws configure`. It will step you through providing it with your API tokens. You’ll need to refer to [AWS’s documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) on how to get that set up.

If you don’t have a region set through your `aws` command line tools, you’ll want to have an environment variable to the region your preferred region. This can solve errors such as `The argument "region" is required, but was not set.`

```bash
# change “us-east-1” to your preferred AWS region, i.e: “us-west-1”, “us-central-1”, etc.
export AWS_DEFAULT_REGION=”us-east-1”
```

1. Copy `deploy/example_env` to a new directory depending on the environment you wish to deploy to. (e.g: `testing`, `production`, etc)

Example:
```bash
cp -a terraform/deploy/example_env terraform/deploy/{testing,production}
cd terraform/deploy/{testing,production}
```

2. Upload encrypted session file to the AWS Secrets Manager. Replace `<aws_region>` with the region you are deploying to.

Example:
```bash
aws secretsmanager create-secret --name op-scim/scimsession --secret-binary file:///path/to/scimsession --region <aws_region> --cli-binary-format raw-in-base64-out
aws secretsmanager describe-secret --secret-id op-scim/scimsession --region <aws_region>
```

Custom Key Management Service key can be specified by `--kms-key-id <kms_key>`. Ensure deployed instances have access to that key. If you don't specify key, AWS Secrets Manager will default to using the AWS account's default Customer Master Key (CMK, the one named `aws/secretsmanager`).

3. Adjust `variables.tf`, `main.tf`, `providers.tf`, and `user_data/03-default-users.yml` as required, paying special attention to variables tagged with `CHANGE_ME`.

4. Ensure that you've manually created a certificate for the subdomain you've specified in `variables.tf` in your AWS Certificate Manager. This is not automatically performed by the deployment script.

5. Use the following `terraform` commands to deploy and verify your installation. From the `terraform/deploy/{testing,production}` directory:

```bash
terraform init
terraform plan -out=./op-scim.plan
terraform apply ./op-scim.plan
```

6. Update/Create 1Password SCIM configuration in your Identity Provider using your generated [bearer token](/PREPARATION.md) and newly-created subdomain.

7. Test your SCIM bridge deployment using the following `curl` command:

```bash
curl --header "Authorization: Bearer TOKEN_GOES_HERE" https://<domain>/scim/Users
```

## Advanced

### Logging

All logs go to `/var/log/syslog` (AWS EC2 instance OS). You can use the AWS System Manager to view logs for your instance.

### Upgrading and Redeployment

You can destroy and redeploy the instance whenever you feel the need to. No permanent data is stored within the SCIM bridge instance itself, as secrets are stored in the AWS Secrets Manager. This is useful for upgrading your SCIM bridge with important bugfix or feature releases.

```bash
  terraform destroy
```

### Debian Package

The 1Password SCIM bridge is distributed as a Debian package and installed automatically during the deployment process. The following commands are run during the deployment:

```bash
curl -L https://apt.agilebits.com/op-scim/1Password.asc 2> /dev/null | apt-key add -
echo '${SCIM_REPO}' > /etc/apt/sources.list.d/op-scimrepo.list
apt-get -y -qq update && apt-get -y -qq install op-scim
echo '10 * * * * root /usr/local/bin/op-scim-upgrade.sh 2>&1 | logger -t op-scim-deploy-cron' > /etc/cron.d/50_op-scim && chmod 0644 /etc/cron.d/50_op-scim
```
