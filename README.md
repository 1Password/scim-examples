# 1Password SCIM Bridge deployment examples

You can deploy 1Password SCIM Bridge on any supported infrastructure that allows ingress from your identity provider and egress to 1Password servers. Here you'll find configuration files and best practices to help with your deployment.


### Before you begin

Before you begin deploying 1Password SCIM Bridge, 
- learn more about [automating provisioning in 1Password using SCIM](https://support.1password.com/scim/).
- review the [Preparation Guide](/PREPARATION.md). The guide will help you plan for some of the technical components of the deployment and consider some issues you may encounter along the way.

## Deployment methods
### Azure
- [Azure Container Apps (CaaS)](https://support.1password.com/scim-deploy-azure/)
- [Azure Kubernetes Service](https://support.1password.com/cs/scim-deploy-azure-kubernetes/)

### Amazon Web Services (AWS)
- ✨ **BETA** [AWS ECS Fargate with CloudFormation](/beta/aws-ecsfargate-cfn)
- [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform)

### Google Cloud (GCP)
- [Google Cloud Run (CaaS)](/beta/google-cloud-run)
- [Google Cloud Marketplace](https://support.1password.com/scim-deploy-gcp/)

### Digital Ocean
- [DigitalOcean App Platform (CaaS)](https://support.1password.com/cs/scim-deploy-digitalocean-ap/)
- [DigitalOcean Marketplace](https://support.1password.com/scim-deploy-digitalocean/)


### Generic
- [Docker](/docker)
- [Kubernetes](/kubernetes)
- [Helm](https://github.com/1Password/op-scim-helm)

## Choosing a deployment method

Choosing a deployment method comes down to which infrastructure and tool you mainly use in your organization. Under the hood they all use the same Docker image and serve the same purpose of a SCIM bridge. Below are some more information on terminologies used in the deployment method list.

### Marketplace
These deployment methods use a marketplace app from Google Cloud Platform or DigitalOcean, and leverages Kubernetes.

### Containers as a service (Caas)
Containers as a service (CaaS) can simplify your deployment by using the built-in tools of the container service for DNS and certificate management. This gives you an easy, low-cost SCIM bridge with minimal infrastructure management requirements.

### Beta
The beta deployments _should_ work, but aren't guaranteed and will change in the future. See the [README](./beta/README.md) for more information about the "beta" designation.

## Deprecated deployment methods

A list of recently-deprecated deployments can be found in [`/deprecated`](./deprecated/). At the time of deprecation, these deployments were fully functional, but will soon become unsupported.

- [**List of deprecated deployment methods**](./deprecated/README.md#deprecated-deployments)

<details>
<summary>Deprecation schedule</summary>

When a deployment method is deprecated, we will simultaneously append a deprecation notice to the deployment name listed in this README and move all files associated with the deployment method to [`/deprecated`](./deprecated/).

Deprecated deployments will remain in [`/deprecated`](./deprecated/) for approximately **three months**, after which time they will be deleted. The deletion date of deprecated deployments will be posted in [`/deprecated/README.md`](./deprecated/README.md).

Where possible, we will provide suggested alternatives in [`/deprecated/README.md`](./deprecated/README.md).
</details>

## Get help

If you encounter issues with your SCIM bridge deployment or have general questions about automated provisioning, [contact 1Password Support](https://support.1password.com/contact/). If you need additional deployment examples or some information in these guides needs improvement, file an issue or open a pull request in this repo to let us know.
