# Beta deployments

This folder contains beta versions of 1Password SCIM bridge deployments.

These deployments _should_ work, but come with no guarantees, and will change in the future.

> **Note**  
> "Beta" refers solely to the deployment _method_. It does not refer to the SCIM bridge software being deployed.

## What are "beta" deployment examples?

We want to provide people deploying 1Password SCIM Bridge with deployment examples suitable for a range of skill levels, environments, and budgets. As part of those efforts, we may choose to make deployment examples available in "beta" form. This gives people deploying 1Password SCIM Bridge more options and provides us with feedback we can use to enhance the deployment example.

### What does "beta" mean?

"Beta" refers to the deployment example. It does not refer to the software being deployed, which in this case is 1Password SCIM Bridge. You will always be deploying a stable version of 1Password SCIM Bridge, regardless of how you've deployed it.

Generally speaking, any new deployment example will start in beta. This allows us better-assesss where documentation could be enhanced, where the deployment could be improved, identify edge-cases we need to accommodate, and so on.

### Is there greater risk associated with beta deployment examples?

Because the software being deployed (1Password SCIM Bridge) is not in beta, there is minimal additional risk associated with using beta deployment examples.

However, due to beta deployment examples being newer, there is a small risk of unforseen challenges with deployment, maintenance, or performance over time.

## Publishing beta deployment example

This section describes:

- The criteria to determine when deployment example is ready to be published with the "beta" label.
- The process for publishing a beta deployment example.

### Criteria for publishing a beta deployment example

It is assumed that any deployment example being devised is broadly useful (within the context of the cloud provider or deployment environment being addressed) and brings value to 1Password SCIM Bridge users that is not already provided by current deployment examples. Value could be in the form of lower cost, ease of deployment, or reduced dependencies compared to other options.

Before being published as a beta deployment example, the following criteria should be met.

- Testing
  - All currently-documented configurations (e.g., Let's Encrypt, custom TLS, Google Workspace, etc) _must_ be tested by at least one person other than the person developing the example. Tests are considered successful if:
    - The SCIM bridge is deployed and acessible over TLS for each configuration being tested.
    - Upgrades or downgrades of the container image are successful.
    - At least one configuration has been tested by connecting it to an IdP provisioning some number of users. The number of users should be representative of the anticipated use case, and provisioning should take place in a timely manner. If the host platform provides resource monitoring, those should be consulted to ensure that the resources available are adequate.
  - Successful deployments _must_ be reliably reproducable when following the accompanying documentation.
  - Deployments or updates _must_ not fail for inexplicable reasons.
- Documentation
  - Documentation for the primary anticipated use case _must_ be complete, though it need not be in it's final form. It is anticipated that documentation will change while in beta.
  - Complete documentation in this context means the following are included:
    - Complete instructions for the most common deployment configuration.
    - Complete instructions for updating the SCIM bridge.
    - If documentation includes command-line instructions, it _must_ include options, where supported, for both Unix and Powershell.
  - Documentation for less common use-cases _may_ be partial or incomplete. If incomplete documentation is procided, it _must_ be noted as incomplete in an obvious way to a reader.
  - Documentation _should_ conform to the [1Password Style Guide](https://support.1password.com/style-guide/).

### Process for publishing a beta deployment example

## Promoting a deployment example out of beta

This section describes:

- The criteria for removing the "beta" label from a deployment example.
- The process for graduating a deployment example from beta to stable.

### Criteria for promoting a deployment example out of beta

- Testing
  - Some criteria for testing TBD
- Documentation

  - Documentation _must_ conform to the [1Password Style Guide](https://support.1password.com/style-guide/).
  - Documentation _must_ include the following:
    - Complete instructions for deployment.
    - Complete instructions for updating.
    - Complete instructions for scaling the SCIM bridge, if applicable.

<!-- Criteria and process go here -->

### Process for promoting a deployment example out of beta

## Deprecating a beta deployment example

If a deployment method is to be removed while in beta, the [standard procedures for deprecating deployment methods](../deprecated/README.md) should be followed.
