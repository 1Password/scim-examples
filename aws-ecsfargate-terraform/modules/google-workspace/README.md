# 1Password SCIM Bridge Google Workspace module

This is a Terraform module to manage the configuration required to integrate 1Password with Google Workspace for automated provisioning. If you want to integrate with a different identity provider, this module isn't necessary and won't be used.

This module:

- Creates AWS secrets to store the Google Workspace configuration.
- Creates an IAM policy to read the secrets and attaches it to the role passed into the module.
- Merges the environment variables and AWS CLI commands into the container definitions passed into the module.

Learn how to use this module in the Terraform deployment example folder's [`README.md`](../../README.md#step-1-configure-the-deployment) document.
