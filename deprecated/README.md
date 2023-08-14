# Deprecated Deployments

This folder contains 1Password SCIM Bridge deployment methods that have been deprecated. At the time of deprecation, these deployments are still fully functional, but will no longer be updated.

> 💡 **Note** that it is solely the _deployment method_ that is deprecated. Deprecating a deployment method is independent of the 1Password SCIM Bridge itself, or a specific version of the 1Password SCIM Bridge. For information about the latest version of 1Password SCIM Bridge, please see the [changelog](https://app-updates.agilebits.com/product_history/SCIM).

## Deployments

| Deployment                                                | Deprecation Date | Deletion Date | Suggested Alternative                                                                                                                |
| --------------------------------------------------------- | ---------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| [aws-ec2-terraform](./aws-terraform)                      | 2020-12-21       | 2023-09-14    | [AWS ECS Fargate with Terraform](../aws-ecsfargate-terraform/) or [AWS ECS Fargate with CloudFormation](./beta/aws-ecsfargate-cfn/)  |
| [DigitalOcean App Platform](./digitalocean-app-platform/) | 2022-12-21       | 2023-09-14    | [Digital Ocean App Platform with `op` CLI](../beta/do-app-platform-op-cli/) or [Azure Container Apps](../beta/azure-container-apps/) |
|                                                           |                  |               |
