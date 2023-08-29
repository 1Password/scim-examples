# 1Password SCIM Bridge Google Workspace module

This is a Terraform module to manage the configuration required to integrate 1Password with Google Workspace for automated provisioning. The module is not necessary for customers integrating with any other identity provider, and is not used unless explicitly enabled by the Terraform deployment example module for 1Password SCIM Bridge.

This module:

- Creates AWS secrets to store the Google Workspace config
- Creates an IAM policy to read the secrets and attaches it to the role passed into the module
- Outputs a list of `secrets` objects to append to the SCIM bridge container definition

Detailed instructions on how to enable and use this module are avaible in the [`README.md`](../README.md#step-1-configure-the-deployment) document in the Terraform deployment example folder.
