# 1Password SCIM bridge Google Workspace module

This is an initial beta release of a Terraform module to manage the configuration required to support automated provisioning with Google Workspace. This module:
- Creates AWS secrets to store the Google Workspace config
- Creates an IAM policy to read the secrets and attaches it to the role passed into the module
- Outputs a list of `secrets` objects to append to the SCIM bridge container definition
