# Deploy 1Password SCIM Bridge on Azure Container Apps using the Azure Portal

_Learn how to deploy 1Password SCIM Bridge on the [Azure Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service._

This deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers): One for the SCIM bridge and another for Redis. There's also an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container. There are a few benefits to deploying 1Password SCIM Bridge on Azure Container Apps:

- For standard deployments, the service will host your SCIM bridge for ~$16 USD/month (as of January 2024). Container Apps pricing is variable based on activity, and you can learn more on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- You don't need to manage a DNS record. Azure Container Apps automatically provides a unique one for your SCIM bridge domain.
- Azure Container Apps automatically handles TLS certificate management on your behalf.
- The SCIM bridge can be deployed directly to Azure from the Portal or via the command line in your local terminal. There is no requirement to clone this repository.

**Table of contents:**

- [Before you begin](#before-you-begin)
- [Step 1: Configure the `scimsession` credentials](#step-1-configure-the-scimsession-credentials)
- [Step 2: Create the container app](#step-2-create-the-container-app)
- [Step 3: Configure and deploy your SCIM bridge](#step-3-configure-and-deploy-your-scim-bridge)
- [Step 4: Connect your identity provider](#step-4-connect-your-identity-provider)
- [Update your SCIM Bridge](#update-your-scim-bridge)
- [Appendix: Resource recommendations](#appendix-resource-recommendations)
- [Appendix: Customize your deployment](#appendix-customize-your-deployment)
- [Get help](#get-help)

## Before you begin

Before you begin, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there. You'll also need the following:

- An Azure account with permissions to create a Container App.

> [!NOTE]
> If you don't have a Azure account, you can sign up for a free trial with starting credit: https://azure.microsoft.com/en-us/free/

- [Azure CLI tool](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with the ContainerApp Extension or access to the [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart) if you'd like to deploy using the command line.

### In this folder

- [`aca-op-scim-bridge.yaml`](./aca-op-scim-bridge.yaml): an Container App configuration file of a container app for the 1Password SCIM bridge.

## Step 1: Configure the `scimsession` credentials

To connect the SCIM bridge with your 1Password account, you'll need to save the `scimsession` credentials as a secret variable in the Container App you create. These credentials need to be Base64-encoded to pass them into the environment, but they're saved as a plaintext file when you download them or save them in your 1Password account during the setup.

> [!IMPORTANT]
> You'll need to update the path to the `scimsession` file you saved during the preparation steps.

Use the following command for your shell to get the Base64 encoded contents of your `scimsession` file:

- **Bash**:

  ```bash
  cat ./scimsession | base64
  ```
- **PowerShell**:

  ```pwsh
  [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path 'scimsession')))
  ```

Copy the output value to your clipboard to use it in the deployment, then save the encoded value in your 1Password account for future use:

1. Find the "scimsession file" item in your 1Password account.
2. Click **Edit**, then choose **Add another field** and select **Password**.
3. Rename the field label to `Base64 value`.
4. Paste the Base64 value from your clipboard into the password field, then click **Save**.

## Step 2: Create the container app

1. Open the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.
2. Click **Create**, then fill out the following fields:
      1. **Resource group**: Choose an existing Resource Group or create a new one.
      2. **Container app name**: Enter a name you'd like to use, such as `op-scim-con-app`.
      3. **Region**: Choose the region you prefer.
      4. **Container App Environment**: Choose an existing one or create a new one with the information in [step 2.1](#21-optional-create-a-container-app-environment).
3. If you didn't create a new Container App Environment, continue to [step 2.2](#22--container-app-environment).

### 2.1: (Optional) Create a new Container App Environment

If you choose to create a new Container App Environment, give it a name that makes sense for your organization, such as `op-scim-con-app-env`. Then adjust the following:

1. **Environment type**: Choose **Consumption only**.
2. **Zone Redundancy**: Choose **Disabled**.

After you adjust these options, click **Create**.

### 2.2: Continue creating the container app

1. On the Create Container App page, click **Next : Container >**.
2. Deselect **Use quickstart image**, then adjust the following:
	1. **Name**: Enter `op-scim-bridge`.
	2. **Image source**: Choose **Docker Hub or other registries**.
	3. **Image and tag:** Enter `1password/scim:v2.9.0`.
	4. **CPU and Memory**: Choose **0.25 CPU cores, 0.5 Gi memory**, which should be the default option.
	5. **Environment variables**: Create two with the following details:
		1. `OP_SESSION` as the Name and  `""` as the Value.
		2. `OP_REDIS_URL` as the Name and `redis://localhost:6379` as the Value.

3. Click **Next: Bindings >** at the bottom of the page, then click **Next : Ingress >** to continue.
4. Click **Enabled** to turn on ingress, then adjust the following:
	1. **Ingress Traffic**: Choose **Accept traffic from anywhere**.
	2. **Target Port**: Enter `3002`.

5. Click **Review + create** at the bottom of the page, then wait a moment for the page to load and click **Create.**

After the deployment is complete, click **Go to resource**, then continue to step 3.

> [!NOTE]
> The deployment will fail because it's expecting the second container to deploy successfully. Continue to step 3 to fully deploy the SCIM bridge.

## Step 3: Configure and deploy your SCIM bridge

### 3.1: Create a secret with your `scimsession` file

1. Choose **Secrets** from the Settings section in the sidebar.
2. Click **Add**, then enter `scimsession` in the Key field.
3. Paste the base64 value into the **Value** field. This is the `scimsession` item that you added to your account in [step 1](#step-1-configure-the-scimsession-credentials).
4. Choose **Add**, then wait until the secret is created.

### 3.2: Create a secret reference

1. Choose **Containers** from Application section in the sidebar.
2. Click **Edit and deploy**.
3. Hover over your **op-scim-bridge** container and select it, then click **Edit**.
4. Scroll down to the environment variables and adjust the following for the **OP_SESSION** variable:
	1. **Source**: Choose **Reference a secret**
	2. **Value**: Choose the **scimsession** secret.

5. Click **Save**.

### 3.3: Create a Redis container

1. Choose **Add** > **App container**.
2. Adjust the following:
    1. **Name**: Enter `op-scim-redis`.
    2. **Image source**: Choose **Docker Hub or other registries**.
    3. **Image and tag**: Enter `redis`.
    4. **CPU cores**: Enter `0.25`
    5. Memory (Gi): Enter `0.5`.
    6. **Environment variables**: Create one with`REDIS_ARGS` as the Name and `--maxmemory 256mb --maxmemory-policy volatile-lru` as the Value.

3. Click **Add**, then click **Next : Scale >**.
4. Drag both ends of the slider to select `1` in both **Scale rule setting** fields.
5. Click **Create**.

### 3.4: Test your SCIM bridge

Wait for the notification that the revision deployment was successful, then choose **Overview**.

To test if your SCIM bridge is online, click **Application Url**. This URL is your SCIM bridge domain. You should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Step 4: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

### If Google Workspace is your identity provider

If Google Workspace is your identity provider, follow the steps in this section to connect it your SCIM bridge.

<details>
<summary>Connect Google Workspace using the Azure Portal</summary>

#### Step 1: Get your Google service account key


1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).

2. Copy and paste the following command for your shell to create a base64 value for your key. Change `<keyfile>` to the filename generated by Google for your service account.
    - **Bash**:
     ```bash
     cat /path/to/<keyfile>.json | base64
     ```
    - **PowerShell:**
     ```pwsh
     [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path '/path/to/<keyfile>.json')))
     ```

3. Open the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.

4. Choose **Secrets** from the Settings section in the sidebar.

5. Click **Add**, the fill out the following fields:
    1. **Key**: Enter `workspace-credentials`.
    2. **Value**: Paste the base64 value you just created.

6. Click **Add**, then wait until the secret is created.

7. Add two environment variables to the new secret:
    1. `OP_WORKSPACE_CREDENTIALS`
    2. `OP_WORKSPACE_SETTING`

#### Step 2: Download and edit the `workspace-settings.json` file

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) file from this repo.
2. Edit the following in the .json file you downloaded:
3. 1. **Actor**: Enter the email address of the administrator in Google Workspace that the service account is acting on behalf of.
	2. **Bridge Address**: Enter your SCIM bridge domain (not your 1Password account sign-in address). This is the Application URL for your Container App found on the overview page. For example: `https://scim.example.com`.
4. Save the file.
5. Run the following command for your shell to create a base64 value for the file.
    - **Bash**:
    ```bash
    cat /path/to/workspace-settings.json | base64
    ```
    - **Using PowerShell**:
    ```pwsh
    [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path '/path/to/workspace-settings.json')))
    ```

#### Step 3: Add the secrets to your container

1. Choose **Secrets** from the Settings section in the sidebar.
2. Click **Add**, then fill out the following fields:
     1. **Key**: Enter `workspace-settings`.
     2. **Value**: Enter the base64 value you just created.

3. Click **Add**, then wait until the secret is created.
4. Choose **Containers** from Application section in the sidebar.
5. Click **Edit and deploy**.
6. Hover over your **op-scim-bridge** container and select it, then click **Edit**.
7. Scroll down to the environment variables and add a new one. Then fill out the following fields:
      1. **Name**: Enter `OP_WORKSPACE_CREDENTIALS`.
      2. **Source**: Choose **Reference a secret**.
      3. **Value**: Select the `workspace-credentials` secret.

8. Create another new variable and fill out the following fields:
      1. Name: **OP_WORKSPACE_SETTINGS**
      2. **Source**: Choose **Reference a secret**.
      3. **Value**: Select the `workspace-settings` secret.

9. Click **Save**, then click **Create**.

</details>

<hr>

## Update your SCIM bridge


> [!TIP]
>
> Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://app-updates.agilebits.com/product_history/SCIM).

You can update your SCIM bridge in the [Azure Cloud Shell](#in-the-azure-cloud-shell-or-az-cli) or the [Azure Portal](#in-the-azure-portal).

### In the Azure Cloud Shell or AZ CLI

1. Open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool.
2. Copy and paste the following command, then replace `$ConAppName` and `$ResourceGroup` with the names from your deployment and change the version number (2.9.0) to match the latest version from the [SCIM bridge release notes page](https://app-updates.agilebits.com/product_history/SCIM).

    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --image docker.io/1password/scim:v2.9.0
    ```

3. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

### In the Azure Portal

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), Select **Containers** from the left hand side.
2. Click **Edit and deploy**.
3. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
4. Change the version number **2.9.0** in the **Image and Tag** field, **1password/scim:v2.9.0** to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updating image.
7. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

## Appendix: Resource recommendations

The pod for 1Password SCIM Bridge should be vertically scaled you provision a large number of users or groups. These are our default resource specifications and recommended configurations for provisioning at scale:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.25  | 0.5Gi  |
| High      | 1,000–5,000     | 0.5   | 1.0Gi  |
| Very high | >5,000          | 1.0   | 1.0Gi  |

If you're provisioning more than 1,000 users, update the resources assigned to the SCIM bridge container to follow these recommendations. The resources specified for the Redis container do not need to be adjusted.

### Default

To revert to the default specification that is suitable for provisioning up to 1,000 users, run the following command:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.25 --memory 0.5Gi
```

### High volume deployment

If you're provisioning up to 5,000 users:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.5 --memory 1.0Gi
```

### Very high volume

If you're provisioning more than 5,000 users:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 1.0 --memory 1.0Gi
```

## Get help

### Region support

When you create or deploy the Container App Environment, Azure may present an error that the region is not supported. You can review Azure documentation to make sure the region you selected supports [Azure Container Apps](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps).

### Container App Name requirements

Your Container App Name, (the `ConAppName` variable) can contain lowercase letters, numbers, and hyphens. It must be between 2 and 32 characters long, cannot start or end with a hyphen, and cannot start with a number. [Learn more about the naming rules and restrictions for Azure resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftapp).

### Viewing Logs in Azure Container Apps

Logs for a container app can be viewed from the **Log Stream**, there is a separate log stream for both containers of the revision that is active. Often reviewing the logs of the **op-scim-bridge** container can help understand any startup issues.

### How to replace your `scimsession` secret in the deployment

After you download a new `scimsession` file, follow the steps below to replace the existing one in your deployment.

<details>
<summary>Replace your `scimsession` secret using the Azure Cloud Shell or AZ CLI</summary>

1. Open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool.

2. Copy and paste the following command, replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.

    - **Bash**:

        ```bash
        az containerapp secret set \
            --name $ConAppName \
            --resource-group $ResourceGroup \
            --secrets scimsession="$(cat $HOME/scimsession | base64)"
        ```

    - **PowerShell**:

        ```pwsh
        az containerapp secret set `
            --name $ConAppName `
            --resource-group $ResourceGroup `
            --secrets scimsession="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $HOME 'scimsession'))))"
        ```

3. Copy and paste the following command, which will have the `op-scim-bridge` container read the new secret. Replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, then run the command.
    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --query properties.latestRevisionName
    ```

    Update the revsion name to use the output of the above command
    ```
    az containerapp revision restart -n $ConAppName -g $ResourceGroup --revision revisionName
    ```

4. Open your SCIM bridge URL in a browser and enter your bearer token to test the bridge.

5. Update your identity provider configuration with the new bearer token.
    </details>

<details>
<summary>Replace your `scimsession` secret using the Azure Portal</summary>

1. Run the following command for your shell to get the Base64 encoded contents of your new `scimsession` file.

    - **Bash**:

        ```bash
        cat ./scimsession | base64
        ```

    - **PowerShell**:

        ```pwsh
        [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path 'scimsession')))
        ```

2. Copy the output value to your clipboard to use it in the deployment.
3. Open the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.
4. Choose **Secrets** from the Settings section in the sidebar.
5. Edit the `scimsession` secret and paste the new value of your secret.
6. Select the checkbox and click **Save**.
7. Choose the **Revisions** from the Application section in the sidebar.
8. Click your current active revision and choose **Restart** in the details pane.
9. Open your SCIM bridge URL in a browser and enter your bearer token to test the bridge.
10. Update your identity provider configuration with the new bearer token.
    </details>
