## 1Password SCIM bridge deployment examples

Here you can find configuration files and best practice instructions for deploying the 1Password SCIM bridge on various public and private cloud providers.

### Before Deploying 

Before you begin deploying the 1Password SCIM bridge, please refer to the [Preparation Guide](https://github.com/1Password/scim-examples/tree/master/PREPARATION.md). You will need to make some decisions about certain key details, and it also contains ways to avoid common pitfalls.

## Automatic (one click) Deployment

The easiest way to deploy the SCIM bridge is with our one-click installations currently available for Google Cloud Platform and DigitalOcean.

- [One-click Google Cloud Platform Marketplace App](https://support.1password.com/cs/scim-deploy-gcp/)
- [One-click DigitalOcean Marketplace App](https://support.1password.com/scim-deploy-digitalocean/)

## Advanced Deployment Guides

Advanced deployment are recommended when you have particular requirements for your environment. They are easily customizable and adaptable to your situation.
- [Kubernetes](/kubernetes)
- [Docker Compose & Docker Swarm](/docker)
- [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform)
- [Azure Kubernetes Service](https://support.1password.com/cs/scim-deploy-azure/)

## Beta deployments

These are beta versions of 1Password SCIM bridge deployments and components. These deployments *should* work, but come with no guarantees, and will change in the future.

- ✨ **NEW** [AWS with CloudFormation](/beta/aws-ecsfargate-cfn)
- [DigitalOcean App Platform with 1Password CLI](/beta/do-app-platform-op-cli/)
- [Google Workspace settings](/beta/workspace-settings.json)
- [Google Workspace module for Terraform](/beta/aws-terraform-gw/)

## Deprecated deployments

These are deprecated 1Password SCIM bridge deployments. At the time of deprecation, these deployments were still fully functional, but may no longer be updated and will eventually be removed:

- [AWS EC2 with terraform](/deprecated/aws-terraform/)
- [DigitalOcean App Platform](/deprecated/digitalocean-app-platform/)

## Support

If you require additional deployment examples, encounter any issues, or have any questions about your SCIM bridge deployment, do not hesitate to email support+business@agilebits.com and open an issue with us. We are happy to help in any way we can.
