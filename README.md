# 1Password SCIM Bridge deployment examples

You can deploy 1Password SCIM Bridge on various public and private cloud providers. Here you'll find configuration files and best practices to help you with the deployment.

## Before you begin

Before you begin deploying 1Password SCIM Bridge, review the [Preparation Guide](https://github.com/1Password/scim-examples/blob/master/PREPARATION.md). The guide will help you plan for some of the technical components of the deployment and consider some issues you may encounter along the way.

## Automatic (one-click) deployment

The easiest way to deploy 1Password SCIM Bridge is with our one-click apps, which are currently available for Google Cloud Platform and DigitalOcean:

- [Deploy 1Password SCIM Bridge on Google Cloud Platform](https://support.1password.com/scim-deploy-gcp/)
- [Deploy 1Password SCIM Bridge on DigitalOcean](https://support.1password.com/scim-deploy-digitalocean/)

## Advanced deployment guides

If you have particular requirements for your environment, an advanced deployment is recommended. These deployments are easily customizable and adaptable to your situation.
- [Kubernetes](/kubernetes)
- [Docker Compose & Docker Swarm](/docker)
- [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform)
- [Azure Kubernetes Service](https://support.1password.com/cs/scim-deploy-azure/)

### Beta deployments

These are beta versions of 1Password SCIM Bridge deployments and components. These deployments *should* work, but aren't guaranteed and will change in the future.

- **NEW** [DigitalOcean App Platform with 1Password CLI](/beta/do-app-platform-op-cli/)
- [Google Workspace settings](/beta/workspace-settings.json)
- [Google Workspace module for Terraform](/beta/aws-terraform-gw/)

### Deprecated deployments

The following are deprecated 1Password SCIM Bridge deployments. At the time of deprecation, these deployments were still fully functional, but may no longer be updated and will eventually be removed.

- [AWS EC2 with terraform](/deprecated/aws-terraform/)
- [DigitalOcean App Platform](/deprecated/digitalocean-app-platform/)

## Support

If you need additional deployment examples, encounter issues, or have questions about your SCIM bridge deployment, contact us at support+business@agilebits.com and we'll be happy to help.
