# Deprecated Deployments

This folder contains 1Password SCIM Bridge deployment methods that have been deprecated. At the time of deprecation, these deployments are still fully functional, but will no longer be updated.

> **Note**  
> It is solely the _deployment method_ that is deprecated. Deprecating a deployment method is independent of 1Password SCIM Bridge itself, or a specific version of 1Password SCIM Bridge. For information about the latest version of 1Password SCIM Bridge, please see the [changelog](https://app-updates.agilebits.com/product_history/SCIM).

## Deprecated deployment method list

The following deployment methods are deprecated and will be removed from the repository on or around the Deletion Date.

| Deployment                                           | Deprecation Date | Deletion Date | Suggested Alternative    | Deprecation PR                                               |
| ---------------------------------------------------- | ---------------- | ------------- | ------------------------ | ------------------------------------------------------------ |
| -                                                    | -                | -             | -                        | -                                                            |

### Deleted deployment methods

The following is a list of deployment methods that are no longer supported and were removed from the repository upon expiration of their deperecation period. These deployment methods are no longer supported. If you previously depended on one of these deployment methods, consider one of the suggested alternatives.

| Deployment                    | Deprecation Date | Deletion Date | Suggested Alternative                                                                                                                | Deprecation and Deletion PRs                                                                                                             |
| ----------------------------- | ---------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| aws-ec2-terraform             | 2020-12-21       | 2023-09-14    | [AWS ECS Fargate with Terraform](/aws-ecsfargate-terraform/) or [AWS ECS Fargate with CloudFormation](/beta/aws-ecsfargate-cfn/)     | Dep: [PR#127](https://github.com/1Password/scim-examples/pull/127) \| Del: [PR#255](https://github.com/1Password/scim-examples/pull/255) |
| DigitalOcean App Platform     | 2022-12-21       | 2023-09-14    | [Digital Ocean App Platform with `op` CLI](/beta/do-app-platform-op-cli/) or [Azure Container Apps](/azure-container-apps/)          | Dep: [PR#222](https://github.com/1Password/scim-examples/pull/222) \| Del: [PR#255](https://github.com/1Password/scim-examples/pull/255) |
| Docker Compose & Docker Swarm | 2024-09-04       | 2025-05-12    | [Docker Swarm](/docker/)                                                                                                             | Dep: [PR#335](https://github.com/1Password/scim-examples/pull/335) \| Del: [PR#360](https://github.com/1Password/scim-examples/pull/360)  |

## Process for deprecating deployment methods

Generally speaking we try to improve existing deployment methods or create additional deployment methods. However, sometimes deployment methods become no longer relevant and so may be deprecated.

Common reasons a deployment method may be deprecated include one or more of:

- It relies on tooling, utilities, or technologies that have themselves been deprecated or where new versions of the utility/technology introduced breaking changes.
- A superior deployment method using the same or similar technologies on the same or similar platform (if applicable) has been developed.

### Steps to deprecate a deployment method

All deprecations will take place through a pull request and must be approved by a 1Password employee.

1. Identify a candidate for deprecation using the [above criteria](#process-for-deprecating-deployment-methods) along with insights from Integrations Support, your experience, and changes to dependencies, required utilities, host platforms, and technologies.
   - There are no hard and fast rules here, and no single criteria. When making deprecation decisions, the focus should be on ensuring the best possible experience for 1Password SCIM Bridge users. This does not immediately imply we maintain everything forever. To produce the best possible experience may require removing non-relevant deployment methods to enable us to focus on more relevant deployment methods.
2. Open a new branch with a name conforming to `deprecate/<deployment-method-name>`
3. Move all assets related to the deployment method to `./deprecated/<deployment-method-name>`
4. Update READMEs
   - To the [Deprecated Deployments table](#deprecated-deployment-method-list) in `deprecated/README.md`:
     - Add the name and link to the updated path of the deployment in `/deprecated`
     - Set `Deprecation Date` to be the current date (to be updated at merge time to the date of the merge)
     - Set `Deletion Date` to be approximately three months from the deprecation date (considering weekends, holidays, or other events). This may or may not be updated along with the deprecation date at merge time.
     - Add link to PR, once known, to the `Deprecation PR` column.
   - To the [README in the repository root](/README.md) add:
     - Prefix the name of the deployment in the list with `**(⚠️ Deprecated)**`.
     - Update the URL of the linked text point to the new path of the deployment in `/deprecated`.
5. Put your PR up for review and approval. In your PR, please include:
   - Justification for the deprecation
   - Why updating or improving the deployment method is not possible or practical
   - Suggestions for existing alternatives, if any
   - Use internal tooling to set a reminder for both User Lifecycle Developers and Solutions Architects to delete the deprecated method on its Deletion Date.

### Steps to delete a deprecated deployment method

Deleting a deprecated deployment that has reached it's Deletion Date will take place through a pull request and must be approved by a 1Password employee.

1. Open a new branch with a name conforming to `remove/<deployment-method-name>`
2. On that branch, remove the directories and files associated with that deployment method.
3. Updated READMEs
   - Remove the deployment method from the [Deprecated deployment method table](README.md#deprecated-deployment-method-list) in `deprecated/README.md`
   - Add the deployment to the [Deleted deployment methods](README.md#deleted-deployment-methods) table.
   - Add link to the PRs used for the original deprecation, and for deletion (once known), to the appropriate column in table.
   - Remove the deployment method from [README in the repository root](../README.md)
4. Put your PR up for review and approval.
