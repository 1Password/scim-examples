# Deploying the 1Password SCIM Bridge in AWS cloud using Terraform 0.12.x

This example describes one of the simplest methods of deploying the 1Password SCIM bridge to AWS cloud.

## General Recommendations on deploying SCIM Bridge to public cloud or private infrastructure

* SCIM requests must be secured via TLS using an API gateway or load balancer (transport security).
* Anonymous access is not supported. A bearer token and session file is required for authentication with the SCIM Bridge and the 1Password service.
* The session file is an encrypted file containing privileged 1Password account credentials. This file is created before the bridge application is deployed. The bearer token combined with the encrypted session file represent an authentication mechanism and must be treated extremely seriously in terms of security.

## Prepare your 1Password Account

Log in to your 1Password account [using this link](https://start.1password.com/settings/provisioning/setup).  It will take you to the setup page for the SCIM bridge.

Follow the on-screen instructions which will guide you through the following steps:

* Create a Provision Managers group
* Create and confirm a Provision Manager user
* Generate your SCIM bridge credentials

You can then download the `scimsession` file and save your bearer token.  The `scimsession` file contains the credentials for the new Provision Manager user.  This user will create, confirm, and suspend users, and create and manage access to groups.  You should use an email address that is unique.

The bearer token and scimsession file combined can be used to sign in to your Provision Manager account. You’ll need to share the bearer token with your identity provider, but it’s important to **never share it with anyone else**. And never share your scimsession file with **anyone at all**.

## OP-SCIM Bridge 

The 1Password SCIM Bridge is distributed as a Debian package and installed automatically during the deployment process. The following commands are included in the AWS EC2 instance user-data:  
```bash
# configure op-scim repo
- curl -L https://apt.agilebits.com/gpg.key 2> /dev/null | apt-key add -
- echo '${SCIM_REPO}' > /etc/apt/sources.list.d/op-scimrepo.list
# install op-scim
- apt-get -y -qq update && apt-get -y -qq install op-scim
# configure op-scim auto update cron job
- echo '10 * * * * root /usr/local/bin/op-scim-upgrade.sh 2>&1 | logger -t op-scim-deploy-cron' > /etc/cron.d/50_op-scim && chmod 0644 /etc/cron.d/50_op-scim
```

The bridge exposes a service listening on TCP port 3002. The bridge must be deployed and protected by an API gateway, proxy, or load balancer supporting TLS. The bridge service runs using unprivileged user/group credentials, and administrators should use a separate user/group for the bridge service. The bridge writes logs to STDOUT allowing collection with a syslog facility. A systemd unit is included in the package and used to manage service operation, service default environment variables can be altered in `/etc/default/op-scim`. The `scimsession` file and a running instance of Redis are required to start the service. By default, 'localhost' Redis server is configured.  

## Logs 
Endpoint writes to STDOUT, thus logs can be processed in a preferred way, for example, send to a remote log collector using rsyslog. A systemd unit file configuration can be used to set a specific _SyslogIdentifier_ in order to filter service logs.

## DNS
It is recommended to deploy DNS across the infrastructure to reference cache cluster/nodes and bridge endpoint by FQDN.

## Additional Considerations
- For most installations, one t3.micro size instance will be adequate to serve IdP requests. Ensure instance performance is monitored, and upgrade instance size if required.
- Protect instance with a security group and restrict remote access, add IAM policies and roles.
- Load balancer or API gateway/proxy requires a valid SSL/TLS certificate and which includes the bridge endpoint domain name.
- AWS Auto-Scaling Group is used to provide an additional level of service availability. We recommend deploying only __one__ instance of the SCIM bridge concurrently for various reasons. If more instances are deployed, it is important that each instance is started using the same session file (or a session file generated from the same 1Password account), as new user accounts require encryption keys from the provision manager account to be confirmed.

## Deployment overview

### Requirements 
- Terraform 0.12.x
- Linux AMI including additional software: aws cli, redis-server, apt-transport-https.  
- [_scim session_](#Prepare-your-1Password-Account) file. OP-SCIM session file is created outside of the infrastructure deployment and has to be available at the time of the deployment.
- Optional, AWS KMS and Secrets Manager. KMS Key is used to encrypt/decrypt Secrets Manager data, for example, session file and must be configured prior to deploying OP-SCIM infrastructure. OP-SCIM bridge has to know where to find the session file. Instance user-data is utilized to configure the environment variables and securely fetch the session file. AWS KMS and AWS Secrets Manager configuration is beyond of the scope of this guide. Please make sure that deployed instances have required access level to KMS keys (if used) and Secrets Manager.
- Optional, AWS S3 bucket for the terraform remote state & Load Balancer logs. S3 buckets are deployed separately prior to the rest of the infrastructure. These buckets can be used to store terraform state file, Load balancer logs and etc.  

 ## Terraform Code Structure
  - _deploy_ - directory contains deployments/environments and separates them from each other. Example: _development_,_staging_, _testing_ and so on.  
    - _variables.tf_ - sets global variables for the specific deployment and provider configuration. This file already has default values for some of the variables, but it is recommended to review all of them.
    - _providers.tf_ - aws and terraform provider configuration.
    - _main.tf_ - invokes required modules and sets module specific variables.
    - _output.tf_ - prints out some of the resources and values.  
    - _deploy/\<new-environment\>/user\_data/03-default-users.yml_ - user configuration, ssh username and key.
    
  - _new-environment_ - can be created by copying an existing one to a new directory and adjusting `variables.tf`, `main.tf`, `providers.tf` as required.
  - _module\_scim\_app_ - deploys the following AWS resources and their dependencies: ASG, ALB, app instances (ASG), instance IAM, instance and LB security groups, public DNS record. ASG monitors instances and automatically adjusts capacity to maintain steady, predictable performance. Capacity is configured in _main.tf_ and instance specific configuration is in _variables.tf_.
  - _module\_scim\_infra_ - deploys underlaying network infrastructure: VPC, subnets, Route Tables, route53, IGW, NGW and their dependencies.

## Deploying using Terraform (ver. 0.12.x)

1. Copy `deploy/example_env` to a new directory according to the established naming conventions. Example: _deploy/development_.

2. Upload Encrypted session file to the AWS Secrets Manager (If required).  
Example:
```bash
aws secretsmanager create-secret --name op-scim-dev/scimsession --secret-binary file:///path/to/scimsession --region <aws_region>
aws secretsmanager describe-secret --secret-id op-scim/scimsession --region <aws_region>
```  
Custom KMS key can be specified by `--kms-key-id <kms_key_arn>`, in this case make sure deployed instances have access to that key, otherwise skip this option. If you don't specify key, then Secrets Manager defaults to using the AWS account's default CMK (the one named `aws/secretsmanager`).  

3. Adjust `variables.tf`, `main.tf` and `providers.tf` as required.   

4. Use your favorite _terraform_ commands to deploy, verify, and troubleshoot it.
```bash
  terraform init
  terraform plan -out=/tmp/op-scim.plan
  # verify plan output
  terraform apply /tmp/op-scim.plan
```

5. Update/Create OP-SCIM endpoint configuration in Azure AD or Okta (IdP) using ALB URL as the endpoint and generated [_Bearer Token_](#Prepare-your-1Password-Account).

6. Application logs are available with the service start up. All logs go to `syslog` (AWS EC2 instance OS). You may consider configuring a "bastion" host or AWS System Manager or assign Public IP address to your instance, in order to be able to login to the deployed EC2 instance to view system logs.  


## Deprovision (destroying) and Re-deploying

Infrastructure is immutable. Instances do not accumulate changes and can be redeployed or replaced with the new ones.

`terraform destroy` (if target is not specified) deletes all but op-scim session file in Secrets Manager (deployed separately).
