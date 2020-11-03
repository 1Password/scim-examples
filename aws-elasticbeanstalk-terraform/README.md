# SCIM bridge with AWS elastic beanstalk

This is only an example of how you could deploy the 1Password SCIM Bridge to your existing AWS infrastructure. As an advanced form of deployment, this AWS/Terraform example can be integrated into your existing infrastructure. Feel free to modify the deployment to suit your specific needs.

# What are we using

We highly recommend using terraform to create this AWS infrastructure, this help reduce the errors while deploying and maintining AWS infrastructure.

# How to deploy the bridge

1. Have the prerequisite "scimsession" file ready, and have read the [preparation document](../Preparation.md)
2. Have terraform on your computer, [terraform download](https://www.terraform.io/downloads.html)
3. Have your aws credentials ready for terraform to load, see [Terraform - AWS provider - authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication)
4. Edit the `input.tf` file so the variable matches what you wanna try
5. Then from the aws-elasticbeanstalk-terraform directory

```sh
terraform init .
terraform plan -out=./op-scim.plan
# Before applying. Carefully read the plan terraform produced.
terraform apply ./op-scim.plan 
```
6. Update/Create 1Password SCIM configuration in your Identity Provider using your generated [bearer token](/PREPARATION.md) and newly-created subdomain.

# How to update the bridge

1. Pull this repository again
2. Make sure the variables matches what you had previously
3. `terraform apply`