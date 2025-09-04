# Deploy 1Password SCIM Bridge on DigitalOcean App Platform using 1Password CLI

_Learn how to deploy 1Password SCIM Bridge on the [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/) service._

This deployment consists of two [resources](https://docs.digitalocean.com/glossary/resource/): a [service](https://docs.digitalocean.com/glossary/service/) for the for the SCIM bridge and an [internal service](https://docs.digitalocean.com/glossary/service/#internal-services) for Redis. There are a few benefits to deploying 1Password SCIM Bridge on DigitalOcean App Platform:

- **Low cost:** For standard deployments, the service will host your SCIM bridge for ~$10 USD/month (as of March 2024). App Platform pricing is variable based on activity. Learn more on [DigitalOcean's pricing page](https://www.digitalocean.com/pricing/app-platform).
- **Automatic DNS record management:** You don't need to manage a DNS record. App Platform automatically provides a unique one for your SCIM bridge domain.
- **Automatic TLS certificate management:** App Platform automatically handles TLS certificate management on your behalf.
- **Multiple deployment options:** You can deploy the SCIM bridge directly to DigitalOcean from your local terminal using this guide, or from the DigitalOcean Apps portal using the [support guide](https://support.1password.com/cs/scim-deploy-digitalocean-ap/). If you're using a custom deployment, cloning this repository is recommended.

## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md). You'll also need:

* A DigitalOcean account with available quota for two droplets.
* 1Password 8 for [Mac](https://1password.com/downloads/mac/) or [Windows](https://1password.com/downloads/windows/) or [Linux](https://1password.com/downloads/linux/).
* [1Password CLI 2.9.0](https://developer.1password.com/docs/cli/get-started/#install) or later.
* [`doctl`](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl)

> [!NOTE]
> If you're using macOS or Linux, you only need to follow [Step 1: Install doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/#step-1-install-doctl) in the `doctl` installation guide.

## Step 1: Set up your command-line tools

After you install 1Password CLI, add your 1Password account, then follow these steps:

1. [Add your 1Password account](https://support.1password.com/add-account/) to 1Password 8 for Mac, Windows or Linux.
2. [Connect 1Password CLI to the 1Password app.](https://developer.1password.com/docs/cli/app-integration/)
3. [Create a DigitalOcean personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) and select scopes for **read** and **write**.
4. Grant access to `doctl`:
	* If you're using macOS or Linux, [configure the DigitalOcean shell plugin](https://developer.1password.com/docs/cli/shell-plugins/digitalocean/#step-2-configure-your-default-credentials) for 1Password CLI. Choose `Import into 1Password…` to save your DigitalOcean personal access token in your 1Password account and authenticate `doctl`.
	* If you're using Windows, follow the steps to [use the API token to grant account access to doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/#go_step-3-use-the-api-token-to-grant-account-access-to-doctl).
5. Run the following command to confirm that `doctl` can authenticate:
	```sh
	doctl account get
	```

## Step 2: Generate and configure 1Password credentials

### 2.1: Generate your `scimsession` file and bearer token

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. [Create a vault](https://support.1password.com/create-share-vaults-teams/#create-a-vault) to store your 1Password SCIM Bridge credentials in. This guide is written with the vault name `op-scim`, but you can change it to something else if you prefer.
3. Choose **[Integrations](https://start.1password.com/integrations/directory)** in the sidebar.
4. Choose your identity provider from the User Provisioning section.
5. Select **Custom**, then choose **Next**.
6. Choose **Save in 1Password** for both the `scimsession` file and bearer token to save them as items in your 1Password account. Save each item in the vault you just created.

### 2.2: Configure your credentials for DigitalOcean

In this step, you'll save the `scimsession` credentials as an environment variable in App Platform, which DigitalOcean will encrypt on your behalf. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a file in your 1Password item.

Copy and paste the following command for your shell to [read the file using its secret reference](https://developer.1password.com/docs/cli/reference/commands/read), encode the credentials, and store them as a new field in the "scimession file" item saved in your 1Password account. If you gave the vault a custom name, replace `op-scim` with the name of your vault, then run the command.

**Bash**:

```sh
op item edit "scimsession file" --vault "op-scim" base64_encoded=$(op read "op://op-scim/scimsession file/scimsession" | base64 | tr -d "\n")
```

**Powershell**:

```pwsh
op item edit "scimsession file" --vault "op-scim" base64_encoded=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(op read "op://op-scim/scimsession file/scimsession"))))
```

## Step 3: Deploy your SCIM bridge

Run the following command for your shell to stream the app spec template from this repository, use [`op inject`](https://developer.1password.com/docs/cli/reference/commands/inject) to load in the Base64-encoded `scimesssion` credentials from your 1Password account, and pipe the output into `doctl`.

**Bash**:

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait
```

**Powershell**:

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait
```

## Step 4: Test your SCIM bridge

After you deploy your SCIM bridge, you'll see a URL in the `Default Ingress` column of the terminal output. This is your **SCIM bridge URL**. Run the following command for your shell to test the connection to 1Password.

Copy the following command, replace `https://op-scim-bridge-example.ondigitalocean.app` with your SCIM bridge URL, then run the command in your terminal to test the connection and view status information.

**Bash**:

```bash
curl --silent --show-error --request GET --header "Accept: application/json" --header "Authorization: Bearer $(
  op read op://${VAULT:-op-scim}/${ITEM:-"bearer token"}/credential
)" https://op-scim-bridge-example.ondigitalocean.app/health
```

**PowerShell**:

```pwsh
Invoke-RestMethod -Method GET -Auth OAuth -Token $(
    op read "op://op-scim/bearer token/credential" | ConvertTo-SecureString -AsPlainText
) -Uri https://op-scim-bridge-example.ondigitalocean.app/health | ConvertTo-Json
```

<details>
<summary>Example JSON response:</summary>

```json
{
  "build": "209131",
  "version": "2.9.13",
  "reports": [
    {
      "source": "ConfirmationWatcher",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "RedisCache",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "SCIMServer",
      "time": "2025-05-09T14:06:56Z",
      "expires": "2025-05-09T14:16:56Z",
      "state": "healthy"
    },
    {
      "source": "StartProvisionWatcher",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    }
  ],
  "retrievedAt": "2025-05-09T14:06:56Z"
}
```

</details>
<br />

To view this information in a visual format, visit your SCIM bridge URL in a web browser. Sign in with your bearer token, then you can view status information and download container log files.

## Step 5: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

### If Google Workspace is your identity provider

Follow the steps in this section to connect your SCIM bridge to Google Workspace.

<details>
<summary>Connect Google Workspace to your SCIM bridge</summary>

#### 5.1: Get your Google service account key

Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client), then [save the file](https://support.1password.com/files/) to the 1Password vault you created in [step 2.1](#21-generate-your-scimsession-file-and-bearer-token). Name the item `workspace-credentials`.

#### 5.2: Download and edit the Google Workspace settings template

Copy and paste the following command for your shell to [read the file using its secret reference](https://developer.1password.com/docs/cli/reference/commands/read), encode the credentials, and store them as a new field in the `workspace-credentials` item you just saved in your 1Password account. If you gave the vault a custom name, replace `op-scim` with the name of your vault, then run the command.

**Bash**:

  ```sh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_credentials=$(op read "op://op-scim/workspace-credentials/workspace-credentials.json" | base64 | tr -d "\n")
  ```

**Powershell**:

  ```pwsh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_credentials=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(op read "op://op-scim/workspace-credentials/workspace-credentials.json"))))
  ```

#### 5.3: Download and edit the Google Workspace settings template

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) file from this repo.
2. Edit the following in this file:
	- **Actor**: Enter the email address of the Google Workspace administrator for the service account.
	- **Bridge Address**: Enter your SCIM bridge domain. Used in [step 4](#step-4-test-your-scim-bridge) to test your SCIM bridge. This isn't your 1Password account sign-in address. For example:  `https://op-scim-bridge-example.ondigitalocean.app`.
3. Save the file.

#### 5.4: Configure the `workspace-settings` file for App Platform

Next, you'll need to create a Base64 value for the `workspace-settings` file. Copy and paste the following command for your shell. If you gave the vault a custom name, replace `op-scim` with the name of your vault, then run the command.

**Bash**:

  ```sh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_settings=$(cat "pathToFile/workspace-settings.json" | base64 | tr -d "\n")
  ```

**Powershell**:

  ```pwsh
  op item edit "workspace-credentials" --vault "op-scim" base64_encoded_settings=$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($(cat "pathToFile/workspace-settings.json"))))
  ```

#### 5.5: Connect Google Workspace

To finish connecting Google Workspace to your SCIM bridge, run the following command to get the [op-scim-bridge-gw.yaml](/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml) file and inject the Base64 values for your Workspace configuration.

**Bash**:

  ```sh
  curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml | op inject | doctl apps create --spec - --wait --upsert
  ```

**Powershell**:

  ```pwsh
  Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/google-workspace/op-scim-bridge-gw.yaml | op inject | doctl apps create --spec - --wait --upsert
  ```

</details>

## Update your SCIM bridge

To update your SCIM bridge, run the following command for your shell.

**Bash**:

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

**Powershell**:

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

The [op-scim-bridge.yaml](./op-scim-bridge.yaml) file that this command uses should have the latest version in it. If the version doesn't match the one on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/), you can download the file and update it before you run the command.

## Appendix: Resource recommendations

The pod for 1Password SCIM Bridge should be vertically scaled if you provision a large number of users or groups. These are our default resource specifications and recommended configurations for provisioning at scale:

| Volume  | Number of users | CPU  | Memory |
| ------- | --------------- | ---- | ------ |
| Default | <1,000          | 0.25 | 0.5Gi  |
| High    | >1,000          | 1.0  | 1.0Gi  |

If you're provisioning more than 1,000 users, update the resources assigned to the SCIM bridge container to follow these recommendations. The resources specified for the Redis container don't need to be adjusted.

#### Default deployment

If you're provisioning up to 1,000 users, run the following command:

**Bash**:

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

**Powershell**:

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
```

#### High-volume deployment

If you're provisioning more than 1,000 users:

1. Download the [`op-scim-bridge.yaml`](/do-app-platform-op-cli/op-scim-bridge.yaml) file and open it in a text editor.
2. Change the `instance_size_slug` value for the `op-scim-bridge` service to `apps-s-1vcpu-1gb-fixed`:

    ```yaml
    services:
    # ...
    - ### ...
      instance_size_slug: apps-s-1vcpu-1gb-fixed
      name: op-scim-bridge
    ```

3. Run the following command (replace `./op-scim-bridge.yaml` with the path to your modified app spec file as needed):

    ```sh
    cat ./op-scim-bridge.yaml | op inject | doctl apps create --spec - --wait --upsert
    ```

## Get help

### Use a custom vault or item name

If you choose a custom name for vault or items where you saved your SCIM bridge credentials, you can override the defaults using the `VAULT` and `ITEM` variables in the secret references. For example:

**Bash**:

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | VAULT="vault name" ITEM="item name" op inject | doctl apps create --spec - --wait
```

**Powershell**:

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | VAULT="vault name" ITEM="item name" op inject | doctl apps create --spec - --wait
```

### Verify server cost before you deploy

To verify the cost of your SCIM bridge deployment with DigitalOcean before you deploy, run the following command for your shell.

**Bash**:

```sh
curl -s https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | doctl apps propose --spec -
```

**Powershell**: 

```pwsh
Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/do-app-platform-op-cli/op-scim-bridge.yaml | doctl apps propose --spec -
```
