# Beta deployments

This folder contains beta versions of 1Password SCIM Bridge deployment examples.

These deployment examples _should_ work, but come with no guarantees, and will change in the future.

> **Note**  
> "Beta" refers solely to the deployment _method_. It does not refer to the 1Password SCIM Bridge software being deployed.

## What are "beta" deployment examples?

We want to provide people deploying 1Password SCIM Bridge with deployment examples suitable for a range of skill levels, environments, and budgets. As part of those efforts, we may choose to make deployment examples available in "beta" form. This gives people deploying 1Password SCIM Bridge more options and provides us with feedback we can use to enhance the deployment example.

### What does "beta" mean?

"Beta" refers to the deployment example. It does not refer to the software being deployed, which in this case is 1Password SCIM Bridge. You will always be deploying a stable version of 1Password SCIM Bridge, regardless of how you've deployed it.

Generally speaking, any new deployment example will start in beta. This allows us to better assess where documentation could be enhanced, where the deployment could be improved, identify edge-cases we need to accommodate, and so on.

### Is there greater risk associated with beta deployment examples?

Because the software being deployed (1Password SCIM Bridge) is not in beta, there is minimal additional risk associated with using beta deployment examples. Review the [criteria for publishing a beta deployment](#criteria-for-publishing-a-beta-deployment-example) to determine if you feel comfortable using a deployment method that meets that criteria. 

However, due to beta deployment examples being newer, there is a small risk of unforseen challenges with deployment, maintenance, or performance over time. There is also the possibility that configuration files used in beta examples may be revised in substantial ways that break their compatibility with existing deployments. This would not impact the stability or performance of an existing deployment. 

## Publishing beta deployment example

This section describes:

- The criteria to determine when deployment example is ready to be published with the "beta" label.
- The process for publishing a beta deployment example.

### Criteria for publishing a beta deployment example

It is assumed that any deployment example being devised is broadly useful (within the context of the cloud provider or deployment environment being addressed) and brings value to 1Password SCIM Bridge users that is not already provided by current deployment examples. Value could be in the form of lower cost, ease of deployment, or reduced dependencies compared to other options.

Before being published as a beta deployment example, the following criteria should be met. 

- Testing
  - All currently-documented configurations (e.g., Let's Encrypt, custom TLS, Google Workspace, etc) _must_ be tested by at least one person other than the person developing the example. Tests are considered successful if:
    - The SCIM bridge is deployed and accessible over TLS for each configuration being tested.
    - Upgrades or downgrades of the container image are successful.
    - At least one configuration has been tested by connecting it to an IdP and provisioning some number of users. The number of users should be representative of the anticipated use case, and provisioning should take place in a timely manner that indicates adequate compute resources are available. If the host platform provides resource monitoring, those tools should be consulted to ensure that the resources available are adequate.
  - Successful deployments _must_ be reliably reproducible when following the accompanying documentation.
  - Deployments or updates _must_ not fail for inexplicable reasons.
- Documentation
  - Documentation for the primary anticipated use case _must_ be complete, though it need not be in it's final form since it is anticipated that documentation will change while in beta. Complete documentation, in this context, means the following are included:
    - Complete instructions for the most common deployment configuration this example targets.
    - Complete instructions for updating the SCIM bridge.
    - Terminal commands, if applicable, _must_ be provided for both Unix shells and Powershell, where the deployment environment supports both.
  - Documentation for less common use-cases _may_ be incomplete. If incomplete documentation is provided, it _must_ be noted as incomplete in an obvious way to the reader.
  - Documentation _must_ indicate approximate provisioning capacity of a SCIM bridge deployed in the documented manner. Documentation for scaling the SCIM bridge is _not_ required.
  - Documentation _should_ conform to the [1Password Style Guide](https://support.1password.com/style-guide/).

### Process for publishing a beta deployment example

- Review the criteria above to ensure your proposed deployment example meets the criteria. 
- Create a PR containing the deployment example.
  - Documentation and all configuration files should be contained in `./beta/<new deployment method name>/`
  - In the PR, briefly describe the rationale for the proposed deployment (e.g., how it improves on existing methods, or how it addresses a use-case not already served).
  - Describe anything that may still need to be implemented (e.g., Google Workspace support, certain vertical scaling, etc).
  - Call out any specific tests or scenarios that you would like the reviewer to focus on. 
- Update README.md at the root of the repository
  - Add the deployment method to the list of beta deployments in [`README.md`](../README.md#beta-deployment) of the repository root in the following format:   
  `- ✨ **NEW** [Deployment Name](/beta/deployment-name)`
- If you are a 1Password employee, assign reviewers from the Solutions Architect or AOP developer teams. 
  - If you are a community member, a 1Password employee will review your PR when time and resources permit.
- The beta deployment example will be merged into Main when:
  - The reviewer(s) have tested the example successfully according to the use case it's designed to address.
  - The documentation conforms to the criteria above. 
  - All outstanding changes requested by reviewers have been addressed in a way that satisfies the reviewer. 
  - The reviewer has, in their sole discretion, determined that the example is worth including in the repository, regardless of how well the example meets the criteria above. 

> **Note**  
> 1Password, in its sole discretion, may choose to not publish examples for _any reason_, even if the example meets or exceeds all of the above criteria. 


## Promoting a deployment example out of beta

This section describes:

- The criteria for promoting a deployment example out of "beta".
- The process for graduating a deployment example from beta to stable.

### Criteria for promoting a deployment example out of beta

A deployment example may be in beta for whatever length of time is required to meet the promotion criteria. 

- Functionality
  - The deployment example _must_ work for all identity providers 1Password supports (unless otherwise exempt from that criteria). 
  - The deployment example _must_ be capable of scaling to accommodate different provisioning needs (unless otherwise exempt from that criteria).
  - The deployment example _must_ provide the complete automated user provisioning experience described by 1Password and in the documentation accompanying the deployment example. 
  - Feedback from customers using the deployment example is nearly universally positive. Any critical feedback has been addressed to the greatest possible extent during the preceeding beta period. 
  - All documented configurations _must_ be tested by the author and at least one reviewer. Tests must reliably succeed.
  - Some number of customers, greater than one (but no specific minimum is prescribed), are known to have used the deployment example in whatever is deemed a "standard" or common configuration for that example.
    - There must be documentation of these deployments, such as if it was assisted by 1Password Solutions Architect or developer. 
  - Ideally at least _one_ customer has used the deployment example to deploy 1Password SCIM Bridge in other, less typical, configurations, if applicable. 
    - There must be documentation of these deployments, such as if it was assisted by 1Password Solutions Architect or developer.
  - SCIM bridges deployed using the deployment example _must_ be in use by customers through at least one SCIM bridge update release with no evidence of failure or issues. 
- Documentation
  - Documentation _must_ conform to the [1Password Style Guide](https://support.1password.com/style-guide/).
  - Documentation _must_ include the following:
    - Complete instructions for deploying 1Password SCIM Bridge
      - If there are multiple potential configurations, all configurations must be documented and configuration examples provided. 
    - Complete instructions for updating 1Password SCIM Bridge.
    - Complete instructions for scaling 1Password SCIM Bridge to support different provisioning volumes, if applicable.

### Process for promoting a deployment example out of beta

Once the above criteria have been met, the deployment example can be promoted out of beta in the following way:
- Create a branch called `promote/<deployment example name>`
- On that branch, move the directory containing the documentation and configuration manifest from `./beta` to the root of the repository. 
- Review all documentation and URL/URI paths in any related files to ensure that the 'beta' is removed from the paths
- If the deployment example merits having update procedures documented on http://support.1password.com/scim-update (this would only be true in rare cases), file an MR on the internal support.1password.com repository with the relevant information and according to the 1Password Technical Writing team's procedures.
- Remove the references to the deployment method in [`./beta/README.md`](README.md) 
- Add the deployment method to the main list of deployments in [`README.md`](../README.md#advanced-deployment) in the following format:   
`- [Deployment Name](./deployment-name)`

## Deprecating a beta deployment example
If a deployment method is to be removed while in beta, the [standard procedures for deprecating deployment methods](../deprecated/README.md) should be followed.
