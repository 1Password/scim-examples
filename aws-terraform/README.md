# Deploying the 1Password SCIM Bridge in AWS cloud using Terraform

This example describes one of the simplest methods of deploying the 1Password SCIM bridge to AWS cloud.

## General Recommendations on deploying SCIM Bridge to public cloud or private infrastructure

* SCIM requests must be secured via TLS using an API gateway or load balancer (transport security)
* Anonymous access is not supported. A bearer token and session file is required for authentication with the SCIM Bridge and the 1Password service.
* The session file is an encrypted file containing privileged 1Password account credentials. This file is created before the bridge application is deployed. The bearer token combined with the encrypted session file represent an authentication mechanism and must be treated extremely seriously in terms of security.

## Session file

The session file must be generated prior to deploying and starting the endpoint service. You can generate the session file and bearer token on the administrator's local system or on the pre-deployed infrastructure and/or utilize your favorite Secrets Manager to securely store and provision it during the application deployment. To generate the session file and bearer token, run the 1Password SCIM Bridge binary in init mode:
```
op-scim init
```  
__Note:__ When prompted for user credentials by the `init` command, use the credentials for the provision manager user and __not__ an Owner or Administrator user.

Init mode will guide the administrator through an interactive process which generates the encrypted session file and bearer token. Although strong encryption is used to secure the session file, prevent unauthorized access to it. Never store the session file in the same place as the bearer token. The bearer token will be required to configure the identity provider (Azure, Okta, etc) to authenticate your connection.

## Bridge server binary 

The 1Password SCIM Bridge binary can be "baked" into an Amazon AMI or downloaded during the deployment process. The bridge exposes a service listening on TCP port 3002. The bridge must be deployed and protected by an API gateway, proxy, or load balancer supporting TLS. The bridge service runs using unprivileged user/group credentials, and administrators should consider creating a separate user/group for the bridge service. The bridge writes logs to STDOUT allowing collection with a syslog facility. A systemd unit can be used to manage service operation. The session file and a running instance of Redis are required to start the service. Service start command example:
```
op-scim --redis-host={cache address} --redis-port={redis port} --session={/path/to/scimsession}
```

__Note:__ If the `--redis-host` and/or `--redis-port` command flags are not passed, the bridge will default to the hostname `redis`, and the port number `6379`, respectively.

Install the service file for op-scim. A [sample](op-scim.service) is provided and you'll need to change the path.

## Logs 
Endpoint writes to STDOUT, thus logs can be processed in any preferred way, for example, send to a remote log collector using rsyslog. A systemd unit file configuration can be used to set a specific _SyslogIdentifier_ in order to filter service logs.

## DNS
It is recommended to deploy DNS across the infrastructure to reference cache cluster/nodes and bridge endpoint by FQDN.

## TLS
TLS is not implemented on the bridge application, thus it is __highly__ recommended that a load balancer or API gateway/proxy be configured to terminate TLS for the bridge endpoint. In the case of AWS, Application (ALB) or Classic (ELB) Load Balancer can terminate TLS and protect the bridge endpoint.

## Additional Considerations
- For most installations, one t2.micro size instance will be adequate to serve IdP requests. Ensure instance performance is monitored, and upgrade instance size if required.
- Protect instance with a security group and restrict remote access, add IAM policies and roles.
- Load balancer or API gateway/proxy requires a valid SSL/TLS certificate and which includes the bridge endpoint domain name.
- Auto-Scaling Groups can be added to the infrastructure to provide an additional level of service availability. We recommend deploying only __one__ instance of the SCIM bridge concurrently for various reasons. If more instances are deployed, it is important that each instance is started using the same session file (or a session file generated from the same 1Password account), as new user accounts require encryption keys from the provision manager account to be confirmed.

## Deployment overview

### Requirements 
- OP-SCIM Endpoint software, for example built into AMI or fetched from the external source during the deployment.
- Linux AMI including additional software: aws cli.
- _scim session_ file
- Optional, AWS KMS and Secrets Manager
- Optional, AWS S3 bucket for the terraform remote state.
- Optional, AWS S3 bucket for Load Balancer logs. 

1. OP-SCIM session file and application binary/package are created outside of the infrastructure deployment and have to be available at the time of the deployment. The same applies to the AMI build, it has to be `baked` separately and include specific software from the _Requirements_ list.  

2. S3 buckets (Optional) are deployed separately prior to the rest of the infrastructure. These buckets can be used to store OP-SCIM software, terraform state file, Load balancer logs and etc.  

3. KMS Key and Secrets Manager (Optional). KMS Key is used to encrypt/decrypt Secrets Manager data, for example: session file and must be configured prior to deploying OP-SCIM infrastructure. SCIM bridge has to know where to find the session file. Instance userdata can be utilized to configure the environment variables and securely fetch the session file. AWS KMS and AWS Secrets Manager configuration is beyond of the scope of this guide. Please make sure that deployed instances have required access level to KMS keys and Secrets Manager.

4. Infrastructure deployment steps.  

  4.1. Upload Encrypted session file to the Secrets Manager.  
Example:
```
aws secretsmanager create-secret --name op-scim/scimsession --kms-key-id <kms_key_arn> --secret-binary file:///path/to/scimsession --region <aws_region>
aws secretsmanager describe-secret --secret-id op-scim/scimsession --region <aws_region>
```  

  4.2. Configure Cache cluster, can be separate or deployed within the same instances.  
  4.3. Prepare the infrastructure (VPC, subnets, Route Tables, route53, IGW, NGW etc).  
  4.4. Deploy application: Auto Scaling Group, Load balancer, Target group, Certificate, DNS Record.  

_NOTE_: Application can be redeployed at any time with minimal or no downtime. For example, new AMI is available or session file is updated.  

5. Application logs are available with the service start up (`step 4.4.`). All logs go to `syslog`.  


 ## Terraform Code Structure
  - _deploy_ - directory contains deployments and separates them from each other. Example: _development_,_staging_, _testing_ and so on.  
    - _variables.tf_ - sets global variables for the specific deployment and provider configuration.
    - _main.tf_ - invokes required modules and sets module specific variables.
    - _output.tf_ - prints out some of the resources and values.  
    
  - _new environment_ - can be created by copying an existing one to a new directory and adjusting `variables.tf`, `main.tf`, `provider_terraform.tf` as required.
  - _module\_scim\_app_ - deploys the following AWS resources and their dependencies: ASG, ALB, app instances (ASG), instance IAM, instance and LB security groups, public DNS record. ASG monitors instances and automatically adjusts capacity to maintain steady, predictable performance. Capacity is configured in _main.tf_ and instance specific configuration is in _variables.tf_.
  - _module\_scim\_infra_ - deploys underlaying network infrastructure: VPC, subnets, Route Tables, route53, IGW, NGW and their dependencies.

## Deploying using Terraform (ver. 0.11.x)

1. Copy existing deploy/\<env\> to a new directory according to the established naming conventions. Example: _deploy/development_.

2. Upload Encrypted session file to the Secrets Manager (If required).  
Example:
```
aws secretsmanager create-secret --name op-scim-dev/scimsession --kms-key-id <kms_key_arn> --secret-binary file:///path/to/scimsession --region <aws_region>
aws secretsmanager describe-secret --secret-id op-scim-dev/scimsession --region <aws_region>
```  

3. Adjust `variables.tf`, `main.tf` and `provider_terraform.tf` as required.   

4. Use your favorite _terraform_ commands to deploy, verify, and troubleshoot it.
```
  terraform init
  terraform plan -out=/tmp/op-scim.plan
  terraform apply /tmp/op-scim.plan
```

5. Update/Create OP-SCIM endpoint configuration in Azure AD or Okta (IdP) using ALB URL as the endpoint and generated _Bearer Token_.


## Deprovision (destroying) and Re-deploying

Infrastructure is immutable. Instances do not accumulate changes and can be redeployed or replaced with the new ones.

`terraform destroy` (if target is not specified) deletes all but op-scim session file in Secrets Manager (deployed separately).
