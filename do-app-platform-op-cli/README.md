# Deploy 1Password SCIM Bridge on DigitalOcean App Platform with 1Password CLI

This deployment example describes how to deploy 1Password SCIM bridge as an app on DigitalOcean's [App Platform](https://docs.digitalocean.com/products/app-platform/) service using [1Password CLI](https://developer.1password.com/docs/cli), the DigitalOcean command line interface ([`doctl`](https://docs.digitalocean.com/reference/doctl/)), and optionally the DigitalOcean [1Password Shell Plugin](https://developer.1password.com/docs/cli/shell-plugins/) (for Mac and Linux users).

Alternatively, you can [deploy 1Password SCIM Bridge to DigitalOcean App Platform using the DigitalOcean portal](https://support.1password.com/cs/scim-deploy-digitalocean-ap/).

The app consists of two [resources](https://docs.digitalocean.com/glossary/resource/): a [service](https://docs.digitalocean.com/glossary/service/) for the SCIM bridge container and an [internal service](https://docs.digitalocean.com/glossary/service/#internal-services) for Redis.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`op-scim-bridge.yaml`](./op-scim-bridge.yaml): an App Platform [app spec](https://docs.digitalocean.com/glossary/app-spec/) for 1Password SCIM bridge [templated with secret references](https://developer.1password.com/docs/cli/secrets-template-syntax) to load secrets from your 1Password account.

**Table of contents:**

- [Overview](#Overview)
- [Prerequisites](#Prerequisites)
- [Getting Started](#Getting-Started)
- [Deploy 1Password SCIM bridge to App Platform](#Deploy-1Password-SCIM-bridge-to-App-Platform)
- [Connect your Identity Provider to your deployed SCIM bridge](#follow-the-steps-to-connect-your-identity-provider-to-the-scim-bridge)
- [Appendix](#Appendix) - Including updating your SCIM bridge, proposing the spec for cost estimates, resource recommendations

## Overview

Deploying 1Password SCIM bridge on App Platform comes with a few benefits:

- For standard deployments, App Platform will host your SCIM bridge for a predictable cost of $10 USD/month (at the time of last review).
- You do not need to manage a DNS record. DigitalOcean automatically provides a unique URL for your SCIM bridge.
- App Platform automatically handles TLS certificate management on your behalf to ensure a secure connection from your identity provider.
- You will deploy 1Password SCIM bridge directly to DigitalOcean from your local terminal. There is no requirement to clone this repository for this deployment.

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > **Note**
  >
  > Try 1Password Business free for 14 days: <https://start.1password.com/sign-up/business>
- A DigitalOcean account with available quota for two droplets
  > **Note**
  >
  > If you don't have a DigitalOcean account, you can sign up for a free trial with starting credit: <https://try.digitalocean.com/freetrialoffer/>
- Access to Zsh or Bash on Mac or Linux, or PowerShell on Windows

## Getting started

### Step 1: Install 1Password and DigitalOcean tools

Install the following on your Mac, Windows or Linux machine:

- 1Password 8 for [Mac](https://1password.com/downloads/mac/) or [Windows](https://1password.com/downloads/windows/) or [Linux](https://1password.com/downloads/linux/)
- [1Password CLI 2.9.0](https://developer.1password.com/docs/cli/get-started/#install) or later
- [`doctl`](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl)
  > **Note**
  >
  > **Only** [Step 1: Install doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl) in the `doctl` installation guide is required for this step for Mac and Linux. 

### Step 2: Add your 1Password account and configure your DigitalOcean credentials.

If you haven't already done so, add your 1Password account and connect 1Password CLI to your desktop app, then configure the DigitalOcean shell plugin:

1. [Add your 1Password account](https://support.1password.com/add-account/) to 1Password 8 for Mac, Windows or Linux.
2. [Connect 1Password CLI to the 1Password app](https://developer.1password.com/docs/cli/about-biometric-unlock#step-1-connect-1password-cli-with-the-1password-app).
3. [Create a DigitalOcean personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) with both read and write scopes.
4. [Configure the DigitalOcean shell plugin](https://developer.1password.com/docs/cli/shell-plugins/digitalocean#step-1-configure-your-default-credentials) for Mac and Linux. Choose `Import into 1Password…` to save your DigitalOcean personal access token in your 1Password account and authenticate `doctl`.
5. Windows users, follow the steps in [Step 3 Use the API token to grant account access to doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl).

Your terminal should now authenticate `doctl` using the access token stored in your 1Password account (you do _not_ need to run `doctl auth init` unless on Windows as detailed in the last step). You can confirm by [retrieving your account details](https://docs.digitalocean.com/reference/doctl/reference/account/get/):

```sh
doctl account get
```

### Step 3: Generate credentials for automated user provisioning with 1Password

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. [Create a vault](https://support.1password.com/create-share-vaults-teams/#create-a-vault) to store your 1Password SCIM bridge credentials. This guide assumes the vault is named `op-scim` by default, but you can change it to something else if you like.
   > **Note**
   >
   > 💻 You have to sign in at 1Password.com to set up automated provisioning, but you can create a vault from any 1Password app, including [1Password CLI](https://developer.1password.com/docs/cli/reference/management-commands/vault#vault-create), for example:
   >
   > ```sh
   > op vault create "op-scim" --description "1Password SCIM bridge credentials" --icon id-card
   > ```
   >
3. Click [Integrations](https://start.1password.com/integrations/directory) in the sidebar.
4. Choose your identity provider from the User Provisioning section.
5. Choose "Custom deployment".
6. Use the "Save in 1Password" buttons for both the `scimsession` file and bearer token to save them as items in your 1Password account. Save each in the `op-scim` vault (or the chosen name for the vault created above). Use the supplied name for these items (or make a note of their names if you choose your own).

### Step 4: Configure the `scimession` credentials for passing to App Platform

The `scimsession` credentials will be saved as an environment variable in App Platform that DigitalOcean automatically encrypts on your behalf. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a file in your 1Password item.

Use 1Password CLI to [read the file using its secret reference](https://developer.1password.com/docs/cli/reference/commands/read), encode the credentials, and store them as a new field in the "scimession file" item saved in your 1Password account:

Using Bash:
```sh
op item edit "scimsession file" --vault "op-scim" base64_encoded=$(op read "op://op-scim/scimsession file/scimsession" | base64 | tr -d "\n")
```

Using Powershell:
```pwsh
op item edit "scimsession file" --vault "op-scim" base64_encoded=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(op read "op://op-scim/scimsession file/scimsession"))))
```

> **Note**
>
> If you used a different vault or item name for your SCIM bridge credentials, replace `op-scim` and `scimsession file` with the respective name(s) you chose.

## Deploy 1Password SCIM bridge to App Platform

Stream the app spec template from this repository, use [`op inject`](https://developer.1password.com/docs/cli/reference/commands/inject) to load in the Base64-encoded `scimesssion` credentials from your 1Password account, then pipe the output into `doctl` to deploy 1Password SCIM bridge.

For example:

Using Bash:
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait
```

Using Powershell:

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait
```

1Password SCIM bridge deploys with a live URL output to the terminal (found under the `Default Ingress` column). This is your SCIM bridge URL. Use your bearer token with the URL to test the connection to 1Password. For example:

Using Bash:
```sh
curl --header "Authorization: Bearer $(op read op://${VAULT:-op-scim}/${ITEM:-"bearer token"}/credential)" https://op-scim-bridge-example.ondigitalocean.app/Users
```

Using Powershell:
```pwsh
Invoke-WebRequest -Method Get -Uri 'https://op-scim-bridge-example.ondigitalocean.app/Users' -Headers @{'Authorization' ="Bearer $(op read "op://op-scim/bearer token/credential")"}
```

You can also access your SCIM bridge by visting the URL in your web browser. Sign in with the bearer token saved in your 1Password account.

## Follow the steps to connect your Identity provider to the SCIM bridge.
 - [Connect your Identity Provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider)

  <details>
  <summary> If Google Workspace is your IdP, connect Google Workspace using the CLI tools</summary>
  The following steps only apply if you use Google Workspace as your identity provider. If you use another identity provider, do not perform these steps and follow the steps in Connectting your Identity Provider (linked above).

  1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).

  2. Configure the `workspace-credentials` for passing to App Platform.
  
  The `workspace-credentials` will be saved as an environment variable in App Platform that DigitalOcean automatically encrypts on your behalf. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a file from configuring your API key.

  Use 1Password CLI to [read the file using its secret reference](https://developer.1password.com/docs/cli/reference/commands/read), encode the credentials, and store them as a new field in the "workspace-credentials" item saved in your 1Password account. Edit the commands to reference the location/path of the file you saved in the last step.

  Using Bash:
  ```sh
  op document create "pathToFile/workspace-credentials.json" --title "workspace-credentials" --vault "op-scim"
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_credentials=$(op read "op://op-scim/workspace-credentials/workspace-credentials.json" | base64 | tr -d "\n")
  ```

  Using Powershell:
  ```pwsh
  op document create "pathToFile/workspace-credentials.json" --title "workspace-credentials" --vault "op-scim"
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_credentials=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(op read "op://op-scim/workspace-credentials/workspace-credentials.json"))))
  ```

  3. Download and open the  [`workspace-settings.json`](/do-app-platform-op-cli/google-workspace/workspace-settings.json)) file in a text editor and replace the values for each key:

  - `actor`: the email address for the administrator that the service account is acting on behalf of
  - `bridgeAddress`: the URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is the Application URL for your Container App found on the overview page. For example: https://op-scim-bridge-example.ondigitalocean.app

  ```json
  {
      "actor":"admin@example.com",
      "bridgeAddress":"https://op-scim-bridge-example.ondigitalocean.app"
  }
  ```

  Save the file.

  4. Configure the `workspace-settings` for passing to App Platform, just like the `workspace-credentials`, this value is passed to the App Platform as a base64 value. Edit the commands to reference the location/path of the file you saved in the last step.

  Using Bash:
  ```sh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_settings=$(cat "pathToFile/workspace-settings.json" | base64 | tr -d "\n")
  ```

  Using Powershell:
  ```pwsh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_settings=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(cat "pathToFile/workspace-settings.json"))))
  ```

  5. Update your deployed by applying the Workspace specific configuration yaml [op-scim-bridge-gw.yaml](/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml) injecting the base64 values for the Workspace configuration.

  Using Bash:
  ```sh
  curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml | op inject | doctl apps create --spec - --wait --upsert
  ```

  Using Powershell:
  ```pwsh
  Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml | op inject | doctl apps create --spec - --wait --upsert
  ```

  </details>

## Appendix

### Supply custom vault and item names

If you chose your own name for the vault and items where you saved your SCIM bridge credentials, you can override the defaults using the `VAULT` and `ITEM` variables in the secret references. For example:

Using Bash:
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | VAULT="vault name" ITEM="item name" op inject | doctl apps create --spec - --wait
```

Using Powershell:
```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | VAULT="vault name" ITEM="item name" op inject | doctl apps create --spec - --wait
```

### Update 1Password SCIM bridge

The latest version of 1Password SCIM bridge is posted on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website, where you can find details about the latest changes. The most recent version should also be pinned in [`op-scim-bridge.yaml`](./op-scim-bridge.yaml), so you can update using the same command as above with the `--upsert` parameter:

Using Bash:
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

Using Powershell:
```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

### Propose the app spec

You can optionally propose the raw app spec template to verify the cost before deploying to DigitalOcean:

Using Bash:
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | doctl apps propose --spec -
```

Using Powershell: 
```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | doctl apps propose --spec -
```

### Resource recommendations

The 1Password SCIM Bridge Pod should be vertically scaled when provisioning a large number of users or groups. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.25  | 0.5Gi  |
| High      | 1,000–5,000     | 0.5   | 1.0Gi  |
| Very high | >5,000          | 1.0   | 1.0Gi  |

If provisioning more than 1,000 users, the resources assigned to the SCIM bridge container should be updated as recommended in the above table. The resources specified for the Redis container do not need to be adjusted.

Our current default resource requirements are:

<details>
  <summary>Default</summary>

To revert to the default specification that is suitable for provisioning up to 1,000 users:

Using Bash:
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

Using Powershell:
```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```
</details>

These values can be scaled down again to the default values after the initial large provisioning event.

<details>
  <summary>High volume deployment</summary>

For provisioning up to 5,000 users:

Download and open [`op-scim-bridge.yaml`](/do-app-platform-op-cli/op-scim-bridge.yaml) file in a text editor and replace the value in line 37:

`instance_size_slug: basic-xs` 
Changing from basic-x**x**s to basic-xs.

```sh
cat pathToFile/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

</details>

<details>
  <summary>Very high volume deployment</summary>

For provisioning more than 5,000 users:

Download and open [`op-scim-bridge.yaml`](/do-app-platform-op-cli/op-scim-bridge.yaml) file in a text editor and replace the value in line 37:

`instance_size_slug: basic-xs`
Changing from basic-x**x**s to basic-xs.

```sh
cat pathToFile/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

</details>
