# 1Password SCIM Bridge deployment examples

You can deploy 1Password SCIM Bridge on any supported infrastructure that allows ingress by your identity provider and egress to 1Password servers. Here you'll find configuration files and best practices to help with your deployment. Learn more about [automating 1Password provisioning with SCIM](https://support.1password.com/scim/).

## Automatic (one-click) deployment

The easiest way to deploy 1Password SCIM Bridge is with our one-click apps, which are currently available for Google Cloud Platform and DigitalOcean:

- [Deploy 1Password SCIM Bridge on Google Cloud Platform](https://support.1password.com/scim-deploy-gcp/)
- [Deploy 1Password SCIM Bridge on DigitalOcean](https://support.1password.com/scim-deploy-digitalocean/)

## Advanced deployment

If you have particular requirements for your environment, an advanced deployment is recommended. These example configurations can be used as a base for a customized deployment.

### Before you begin

Before you begin deploying 1Password SCIM Bridge, review the [Preparation Guide](/PREPARATION.md). The guide will help you plan for some of the technical components of the deployment and consider some issues you may encounter along the way.

After you've read the preparation guide, refer to the deployment example for your infrastructure:

- [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform)
- [Azure Kubernetes Service](https://support.1password.com/scim-deploy-azure/)
- [Docker Compose & Docker Swarm](/docker)
- [Kubernetes](/kubernetes)

### Beta deployment

These are beta versions of 1Password SCIM Bridge deployments and components. These deployments _should_ work, but aren't guaranteed and will change in the future.

- ✨ **NEW** [AWS with CloudFormation](/beta/aws-ecsfargate-cfn)
- ✨ **NEW** [Azure Container App](/beta/azure-container-apps)
- [DigitalOcean App Platform with 1Password CLI](/beta/do-app-platform-op-cli/)
- [Google Workspace settings](/beta/workspace-settings.json)
- [Google Workspace module for Terraform](/beta/aws-terraform-gw/)

## Deprecated deployment methods

A list of recently-deprecated deployments can be found in [`/deprecated`](./deprecated/). At the time of deprecation, these deployments were fully functional, but will soon become unsupported.

* [**List of deprecated deployment methods**](./deprecated/README.md#deprecated-deployments)

### Deprecation schedule

When a deployment method is deprecated, we will simultaneously append a deprecation notice to the deployment name listed in this README and move all files associated with the deployment method to [`/deprecated`](./deprecated/). 

Deprecated deployments will remain in [`/deprecated`](./deprecated/) for approximately **three months**, after which time they will be deleted. The deletion date of deprecated deployments will be posted in [`/deprecated/README.md`](./deprecated/README.md).

Where possible, we will provide suggested alternatives in [`/deprecated/README.md`](./deprecated/README.md).

## Get help

If you encounter issues with your SCIM bridge deployment or have general questions about automated provisioning, [contact 1Password Support](https://support.1password.com/contact/). If you need additional deployment examples or some information in these guides needs improvement, file an issue or open a pull request in this repo to let us know.
