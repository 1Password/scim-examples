# [Beta] Deploy 1Password SCIM bridge on DigitalOcean App Platform with 1Password CLI

This deployment example describes how to deploy 1Password SCIM bridge as an app on DigitalOcean's [App Platform](https://docs.digitalocean.com/products/app-platform/) service using [1Password CLI](https://developer.1password.com/docs/cli), [`doctl`](https://docs.digitalocean.com/reference/doctl/), and the DigitalOcean [1Password Shell Plugin](https://developer.1password.com/docs/cli/shell-plugins/).

The app consists of two [resources](https://docs.digitalocean.com/glossary/resource/): a [service](https://docs.digitalocean.com/glossary/service/) for the SCIM bridge container and an [internal service](https://docs.digitalocean.com/glossary/service/#internal-services) for Redis.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`op-scim-bridge.yaml`](./op-scim-bridge.yaml): an App Platform [app spec](https://docs.digitalocean.com/glossary/app-spec/) for 1Password SCIM bridge [templated with secret references](https://developer.1password.com/docs/cli/secrets-template-syntax) to load secrets from your 1Password account.

## Overview

Deploying 1Password SCIM bridge on App Platform comes with a few benefits:

- For standard deployments, App Platform will host your SCIM bridge for a predictable cost of $10 USD/month (at the time of last review).
- You will not need to set up a DNS record. DigitalOcean automatically provides a URL for your SCIM bridge.
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
- A Mac or Linux terminal with Bash, Zsh, or Fish
<!--
TODO: Investigate Windows Terminal, Powershell, WSL
-->

## Getting started

### Step 1: Install 1Password and DigitalOcean tools

Install the following on your Mac or Linux machine:

- 1Password 8 for [Mac](https://1password.com/downloads/mac/) or [Linux](https://1password.com/downloads/linux/)
- [1Password CLI 2.9.0](https://app-updates.agilebits.com/product_history/CLI2) or later
- [`doctl`](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl)
  > **Note**
  >
  > **Only** [Step 1: Install doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl) in the `doctl` installation guide is required for this step.

### Step 2: Add your 1Password account and configure the DigitalOcean shell plugin

If you haven't already done so, add your 1Password account and connect 1Password CLI to your desktop app, then configure the DigitalOcean shell plugin:

1. [Add your 1Password account](https://support.1password.com/add-account/) to 1Password 8 for Mac or Linux.
2. [Connect 1Password CLI to the 1Password app](https://developer.1password.com/docs/cli/about-biometric-unlock#step-1-connect-1password-cli-with-the-1password-app).
3. [Create a DigitalOcean personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) with both read and write scopes.
4. [Configure the DigitalOcean shell plugin](https://developer.1password.com/docs/cli/shell-plugins/digitalocean#step-1-configure-your-default-credentials). Choose `Import into 1Password…` to save your DigitalOcean personal access token in your 1Password account and authenticate `doctl`.

Your terminal should now authenticate `doctl` using the access token stored in your 1Password account (you do _not_ need to run `doctl auth init`). You can confirm by [retrieving your account details](https://docs.digitalocean.com/reference/doctl/reference/account/get/):

```sh
doctl account get
```

### Step 3: Generate credentials for automated user provisioning to 1Password

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. [Create a vault](https://support.1password.com/create-share-vaults-teams/#create-a-vault) to store your 1Password SCIM bridge credentials. This guide assumes the vault is named `op-scim` by default, but you can change it to something else if you like.
   > **Note**
   >
   > 👀 You have to sign in at 1Password.com to set up automated provisioning, but you can create a vault from any 1Password app, including [1Password CLI](https://developer.1password.com/docs/cli/reference/management-commands/vault#vault-create), for example:
   >
   > ```sh
   > op vault create op-scim --description "1Password SCIM bridge credentials"  --icon id-card
   > ```
   >
3. Click [Integrations](https://start.1password.com/integrations/directory) in the sidebar.
4. Choose your identity provider from the User Provisioning section.
5. Choose Custom deployment.
6. Use the "Save in 1Password" buttons for both the `scimsession` file and bearer token to save them as items in your 1Password account. Save each in the `op-scim` vault (or the chosen name for the vault created above). Use the supplied name for these items (or make a note of their names if you choose your own).

### Step 4: Configure the `scimession` credentials for passing to App Platform

The `scimsession` credentials will be saved as an environment variable in App Platform that DigitalOcean automatically encrypts on your behalf. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a file in your 1Password item.

Use 1Password CLI to [read the file using its secret reference](https://developer.1password.com/docs/cli/reference/commands/read), encode the credentials, and store them as a new field in the "scimession file" item saved in your 1Password account:

```sh
op item edit "scimsession file" --vault "op-scim" base64_encoded=$(op read "op://op-scim/scimsession file/scimsession" | base64)
```

> **Note**
>
> If you used a different vault or item name for your SCIM bridge credentials, replace `op-scim` and `scimsession file` with the respective name(s) you chose.

## Deploy 1Password SCIM bridge to App Platform

Stream the app spec template from this repository, use [`op inject`](https://developer.1password.com/docs/cli/reference/commands/inject) to load in the Base64-encoded `scimesssion` credentials from your 1Password account, then pipe the output into `doctl` to deploy 1Password SCIM bridge:

For example, with `curl`:

<!-- TODO: update to path on main -->
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/pike/do-app-platform-op-cli/beta/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait
```

1Password SCIM bridge deploys with a live URL output to the terminal (found under the `Default Ingress` column). Use this with your bearer token to [connect to 1Password SCIM bridge from your supported identity provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

<!-- TODO: Add testing instructions (browser/CLI) -->

## Appendix

<!--
### Updating

TODO: Add instructions for updating to latest release UPSERT FTW

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/pike/do-app-platform-op-cli/beta/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

-->

### Supply custom vault and item names

If you chose your own name for the vault and items where you saved your SCIM bridge credentials, you can override the defaults using the `VAULT` and `ITEM` variables in the template's secret reference with `op inject`:

<!-- TODO: update to path on main -->
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/pike/do-app-platform-op-cli/beta/do-app-platform-op-cli/op-scim-bridge.yaml | VAULT="vault name" ITEM="item name" op inject | doctl apps create --spec - --wait
```

### Propose the app spec

Without loading any secrets from your 1Password account, you can optionally propose the raw app spec template to verify the cost before deploying to DigitalOcean:

<!-- TODO: update to path on main -->
```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/pike/do-app-platform-op-cli/beta/do-app-platform-op-cli/op-scim-bridge.yaml | doctl apps propose --spec -
```

<!--
### Scaling

TODO: Add instructions for vertical scaling

```sh

```
 -->

<!-- TODO: Allow Workspace credentials to be loaded -->
