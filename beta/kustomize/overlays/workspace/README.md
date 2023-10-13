# Workspace Overlay

This section is only relevant if Google Workspace is your identity provider. 

## Create a Google service account

Create a Google service account and key as outlined in the 1Password support article [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client). 

Download the credentials file provided by Google and save a copy to your 1Password account. 

## Prepare your Google Workspace credential file

Place the credentials file in the `overlays/workspace` folder. The kustomization overlay will create this as an additional secret.

## Prepare your Google Workspace settings file

Edit the file `workspace-settings.json` and fill in correct values for:

- **Actor**: The email address of the administrator in Google Workspace that the service account is acting on behalf of.
- **Bridge Address**: The URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is most often a subdomain of your choosing on a domain you own. If you're using the Let's Encrypt overlay, this would be the value of `OP_TLS_DOMAIN` configured in `patch-configmap.yaml`