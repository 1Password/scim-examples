# 1Password SCIM Bridge deployment examples

You can deploy 1Password SCIM Bridge on any supported infrastructure that allows ingress by your identity provider and egress to 1Password servers. Here you'll find configuration files and best practices to help with your deployment.

> [!TIP]
> Before you deploy your SCIM bridge, learn more about [automating provisioning in 1Password using SCIM](https://support.1password.com/scim/).

## Marketplace apps

For an automated deployment of 1Password SCIM Bridge where some settings are pre-configured for you, use a marketplace app from Google Cloud Platform or DigitalOcean:

- [Deploy 1Password SCIM Bridge on Google Cloud Platform](https://support.1password.com/scim-deploy-gcp/)
- [Deploy 1Password SCIM Bridge on DigitalOcean](https://support.1password.com/scim-deploy-digitalocean/)

## Custom deployment

To customize your deployment, you can use containers as a service or create your own advanced deployment with the examples below as your base.

### Before you begin

Before you begin deploying 1Password SCIM Bridge, review the [Preparation Guide](/PREPARATION.md). The guide will help you plan for some of the technical components of the deployment and consider some issues you may encounter along the way.

### Containers as a service deployment options

Containers as a service (CaaS) can simplify your deployment by using the built-in tools of the CaaS for DNS and certificate management. This gives you an easy, low-cost SCIM bridge with minimal infrastructure management requirements.

- Azure Container Apps
  - [CLI Deployment](https://support.1password.com/scim-deploy-azure/) - recommended for most Azure Container App deployments
  - [Azure Portal Deployment using an ARM Template](/azure-container-apps-arm/README.md) - recommended for those not able to use the tools in the above CLI deployment guide, faster than the manual guide below.
  - [Azure Portal Deployment (Manual)](/azure-container-apps/README.md) - recommended for those not able to use the tools in the above CLI deployment guide
  - [Container Apps advanced customizations](/azure-container-apps/ADVANCED.md)
- DigitalOcean App Platform 
  - [DigitalOcean Portal Deployment](https://support.1password.com/cs/scim-deploy-digitalocean-ap/)
  - [DigitalOcean command line tool & the 1Password CLI Deployment](/do-app-platform-op-cli) 

### Advanced deployment options
If you have particular requirements for your environment, we recommend an advanced deployment. These example configurations will give you a base to create the deployment from, as well as explain what 1Password SCIM Bridge needs to function and how to maintain your bridge once you've deployed it.

- [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform)
- [Azure Kubernetes Service](https://support.1password.com/cs/scim-deploy-azure-kubernetes/)
- [Docker Compose & Docker Swarm](/docker)
- [Kubernetes](/kubernetes)

### Beta deployment

These are beta versions of 1Password SCIM Bridge deployment examples. These deployments _should_ work, but aren't guaranteed and will change in the future. See the [README](./beta/README.md) for more information about the "beta" designation.

- [AWS with CloudFormation](/beta/aws-ecsfargate-cfn)
- [Docker](/beta/docker)
- ✨ **NEW** [Google Cloud Run](/beta/google-cloud-run)

## Deprecated deployment methods

A list of recently-deprecated deployments can be found in [`/deprecated`](./deprecated/). At the time of deprecation, these deployments were fully functional, but will soon become unsupported.

- [**List of deprecated deployment methods**](./deprecated/README.md#deprecated-deployments)

### Deprecation schedule

When a deployment method is deprecated, we will simultaneously append a deprecation notice to the deployment name listed in this README and move all files associated with the deployment method to [`/deprecated`](./deprecated/).

Deprecated deployments will remain in [`/deprecated`](./deprecated/) for approximately **three months**, after which time they will be deleted. The deletion date of deprecated deployments will be posted in [`/deprecated/README.md`](./deprecated/README.md).

Where possible, we will provide suggested alternatives in [`/deprecated/README.md`](./deprecated/README.md).

## Get help

If you encounter issues with your SCIM bridge deployment or have general questions about automated provisioning, [contact 1Password Support](https://support.1password.com/contact/). If you need additional deployment examples or some information in these guides needs improvement, file an issue or open a pull request in this repo to let us know.
