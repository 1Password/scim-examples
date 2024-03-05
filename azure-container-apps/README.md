# Deploy 1Password SCIM Bridge on Azure Container Apps using the Azure Portal

_Learn how to deploy 1Password SCIM Bridge on the [Azure Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service._

This deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers): One for the SCIM bridge and another for Redis. There's also an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container. There are a few benefits to deploying 1Password SCIM Bridge on Azure Container Apps:

- **Low cost:** For standard deployments, the service will host your SCIM bridge for ~$16 USD/month (as of January 2024). Container Apps pricing is variable based on activity, and you can learn more on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- **Automatic DNS record management:** You don't need to manage a DNS record. Azure Container Apps automatically provides a unique one for your SCIM bridge domain.
- **Automatic TLS certificate management:** Azure Container Apps automatically handles TLS certificate management on your behalf.
- **Multiple deployment options:** The SCIM bridge can be deployed directly to Azure from the Portal using this guide or via the Azure Shell or command line tools in your local terminal using the [support guide](https://support.1password.com/scim-deploy-azure/). If you're using a custom deployment, cloning this repository is recommended.

**Table of contents:**

- [Before you begin](#before-you-begin)
- [Step 1: Configure the `scimsession` credentials](#step-1-configure-the-scimsession-credentials)
- [Step 2: Create the container app](#step-2-create-the-container-app)
- [Step 3: Configure and deploy your SCIM bridge](#step-3-configure-and-deploy-your-scim-bridge)
- [Step 4: Connect your identity provider](#step-4-connect-your-identity-provider)
- [Update your SCIM Bridge](#update-your-scim-bridge-in-the-azure-portal)
- [Appendix: Resource recommendations](#appendix-resource-recommendations)
- [Get help](#get-help)

## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md). You'll also need an Azure account with permission to create a Container App.

> [!NOTE]
> If you don't have an Azure account, you can sign up for a free trial with starting credit: https://azure.microsoft.com/free/

## Step 1: Create the Container App

1. Sign in to the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.
2. Click **Create**, then fill out the following fields:
      - **Resource group**: Choose an existing Resource Group or create a new one.
      - **Container app name**: Enter a name you'd like to use, such as `op-scim-con-app`.
      - **Region**: Choose the region you prefer.
      - **Container App Environment**: Choose an existing Container App environment or create a new one with the information in [step 2.1](#21-optional-create-a-new-container-app-environment).
3. If you didn't create a new Container App Environment, continue to [step 1.2](#12-create-the-container-app-and-deploy-redis).

### 1.1: (Optional) Create a new Container App Environment

If you choose to create a new Container App Environment, give it a name that makes sense for your organization, such as `op-scim-con-app-env`. Then adjust the following:

1. **Environment type**: Choose **Consumption only**.
2. **Zone Redundancy**: Choose **Disabled**.

After you adjust these options, click **Create**.

### 1.2: Create the Container App and deploy Redis

1. On the Create Container App page, click **Next: Container >**.
2. Deselect **Use quickstart image**, then adjust the following:
    - **Name**: Enter `op-scim-redis`.
    - **Image source**: Choose **Docker Hub or other registries**.
    - **Image and tag:** Enter `redis`.
    - **CPU and Memory**: Choose **0.25 CPU cores, 0.5 Gi memory**, which should be the default option.
    - **Command override**: Enter `redis-server, --maxmemory 256mb, --maxmemory-policy volatile-lru, --save ""`
3. Click **Review + create** at the bottom of the page. When the page loads, click **Create.**

After the deployment is complete, click **Go to resource**, then continue to step 2.

## Step 2: Create a secret for your `scimsession` credentials

1. Choose **Secrets** from the Settings section in the sidebar.
2. Click **Add**, then enter `scimsession` in the Key field.
3. Paste the plain-text contents of the `scimession` file into the **Value** field.
4. Choose **Add**, then wait until the secret is created.

### Step 3: Deploy the SCIM bridge container

1. Choose **Add** > **App container**.
2. Adjust the following:
    - **Name**: Enter `op-scim-bridge`.
    - **Image source**: Choose **Docker Hub or other registries**.
    - **Image and tag**: Enter `1password/scim:v2.9.0`.
    - **CPU cores**: Enter `0.25`
    - Memory (Gi): Enter `0.5`.
3. Choose "Volume mounts". Click "Create new volume". Adjust the following:
    - **Volume type**: Choose Secret.
    - **Name**: Enter `credentials`
    - **Mount all secrets:** should already be selected, but select it if is not.
4. Click **Add** to save the volume specification. You should see the new `credentials` volume listed under **Volume name**.
5. In the `Mount path` field for this volume, enter `/home/opuser/.op`.
6. Click **Create**.

### Step 4: Enable ingress to your SCIM bridge

1. Wait for the notification that the revision deployment was successful, then choose **Ingress** from the Settings section in the sidebar.
2. Select **Enabled** to allow and configure ingress. Adjust the following:
    - **Ingress traffic**: Choose **Accepting traffic from anywhere**.
    - **Client certificate mode**: Choose **Ignore**, which should be the selected option.
    - **Target port**: Enter `3002`.
3. Click **Save**.

### Step 5: Test your SCIM bridge

Choose **Overview**.

To test if your SCIM bridge is online, click **Application Url**. This URL is your SCIM bridge domain. You should be able to enter your bearer token to verify that your SCIM bridge is up and running.

## Step 6: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

### If Google Workspace is your identity provider

If Google Workspace is your identity provider, follow the steps in this section to connect it to your SCIM bridge.

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

5. Click **Add**, then fill out the following fields:
    1. **Key**: Enter `workspace-credentials`.
    2. **Value**: Paste the base64 value you just created.

6. Click **Add**, then wait until the secret is created.

#### Step 2: Download and edit the `workspace-settings.json` file

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) file from this repo.
2. Edit the following in the .json file you downloaded:
    1. **Actor**: Enter the email address of the Google Workspace administrator for the service account.
    2. **Bridge Address**: Enter your SCIM bridge domain. This is the Application URL for your Container App, found on the overview page (not your 1Password account sign-in address). For example: `https://scim.example.com`.
3. Save the file.
4. Run the following command for your shell to create a base64 value for the file.
    - **Bash**:
    ```bash
    cat /path/to/workspace-settings.json | base64
    ```
    - **PowerShell**:
    ```pwsh
    [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path '/path/to/workspace-settings.json')))
    ```

#### Step 3: Add the secrets to your container

1. Choose **Secrets** from the Settings section in the sidebar.
2. Click **Add**, then fill out the following fields:
     1. **Key**: Enter `workspace-settings`.
     2. **Value**: Enter the base64 value you just created.

3. Click **Add**, then wait until the secret is created.
4. Choose **Containers** from the Application section in the sidebar.
5. Click **Edit and deploy**.
6. Hover over your **op-scim-bridge** container and select it, then click **Edit**.
7. Scroll down to the environment variables. Create a new variable with the following fields:
      1. **Name**: Enter `OP_WORKSPACE_CREDENTIALS`.
      2. **Source**: Choose **Reference a secret**.
      3. **Value**: Select the `workspace-credentials` secret.

8. Create another new variable with the following fields:
      1. Name: **OP_WORKSPACE_SETTINGS**
      2. **Source**: Choose **Reference a secret**.
      3. **Value**: Select the `workspace-settings` secret.

9. Click **Save**, then click **Create**.

</details>

<details>
<summary>Connect Google Workspace using the Azure Cloud Shell or AZ CLI</summary>

#### Step 1: Get your Google service account key

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Open the [Azure Shell](https://shell.azure.com/) or open a new terminal window with the `az` CLI.
3. Upload your `workspace-credentials.json/<keyfile>` file to the Cloud Shell. Click the **Upload/Download files** button in your Cloud Shell and choose **Upload**.
4. Select the `<keyfile>.json` file that you saved to your computer
5. Make note of the upload destination, then click **Complete**.

#### Step 2: Download and edit the `workspace-settings.json` file

1. Run the following command for your shell to get the `./google-workspace/workspace-settings.json` file.
    - **Bash**:
    ```bash
    curl https://raw.githubusercontent.com/1Password/scim-examples/solutions/main/azure-container-apps/google-workspace/workspace-settings.json --output workspace-settings.json --silent
    ```
    - **PowerShell**:
    ```pwsh
    Invoke-RestMethod -Uri `https://raw.githubusercontent.com/1Password/scim-examples/solutions/main/azure-container-apps/google-workspace/workspace-settings.json -OutFile workspace-settings.json
    ```
2. Edit the following in the .json file:
    1. **Actor**: Enter the email address of the Google Workspace administrator for the service account.
    2. **Bridge Address**: Enter your SCIM bridge domain. This is the Application URL for your Container App, found on the overview page (not your 1Password account sign-in address). For example: `https://scim.example.com`.
3. Save the file.
4. Copy and paste the following command for your shell, replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.
    - **Bash**:
    ```bash
    az containerapp secret set \
    --name $ConAppName \
    --resource-group $ResourceGroup \
    --secrets workspace-creds="$(cat $HOME/workspace-credentials.json | base64)"
    ```
    - **PowerShell**:
    ```pwsh
    az containerapp secret set `
    --name $ConAppName `
    --resource-group $ResourceGroup `
    --secrets workspace-creds="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $HOME 'workspace-credentials.json'))))"
    ```
5. To restart your SCIM bridge so it can use the new secret, copy and paste the following command. Replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.
    ```
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_WORKSPACE_CREDENTIALS=secretref:workspace-creds OP_WORKSPACE_SETTINGS=secretref:workspace-settings
    ```

</details>

<hr>

## Update your SCIM bridge in the Azure Portal

> [!TIP]
> Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://app-updates.agilebits.com/product_history/SCIM).

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Change the version number **2.9.0** in the **Image and Tag** field, **1password/scim:v2.9.0** to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updated image.
7. Enter your SCIM bridge URL in a browser and sign in with your bearer token.
8. Check the top left-hand side of the page to verify you're running the updated version of the SCIM Bridge.

After you sign in to your SCIM bridge, the [Automated User Provisioning page](https://start.1password.com/integrations/active/) in your 1Password account will also update with the latest access time and SCIM bridge version.

## Appendix: Resource recommendations

The pod for 1Password SCIM Bridge should be vertically scaled if you provision a large number of users or groups. These are our default resource specifications and recommended configurations for provisioning at scale:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.25  | 0.5Gi  |
| High      | 1,000–5,000     | 0.5   | 1.0Gi  |
| Very high | >5,000          | 1.0   | 1.0Gi  |

If you're provisioning more than 1,000 users, update the resources assigned to [the SCIM bridge container](#22-continue-creating-the-container-app) to follow these recommendations. The resources specified for the Redis container don't need to be adjusted.

> [!TIP]
> Learn more about [Container App Name (``ConAppName`) variable requirements](#container-app-name-requirements) that are referenced in the commands below.

### Default deployment

If you're provisioning up to 1,000 users, run the following command:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.25 --memory 0.5Gi
```

### High-volume deployment

If you're provisioning between 1,000 and 5,000 users, run the following command:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.5 --memory 1.0Gi
```

### Very high-volume deployment

If you're provisioning more than 5,000 users, run the following command:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 1.0 --memory 1.0Gi
```

## Get help

### Region support

When you create or deploy the Container App Environment, Azure may present an error that the region isn't supported. You can review Azure documentation to make sure the region you selected supports [Azure Container Apps](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps).

### Container App Name requirements

Your Container App Name (the `ConAppName` variable) can contain lowercase letters, numbers, and hyphens. It must be 2 to 32 characters long, cannot start or end with a hyphen, and cannot start with a number. [Learn more about the naming rules and restrictions for Azure resources](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftapp).

### Viewing logs in Azure Container Apps

You can [view logs for a container app](https://learn.microsoft.com/azure/container-apps/log-streaming?tabs=bash#view-log-streams-via-the-azure-portal) in the **Log Stream** area of your environment or container app in the Azure portal. If you're having an issue starting up the SCIM bridge, reviewing the **op-scim-bridge** container logs can help you identify the problem.

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
8. Click your current active revision and choose **Restart** in the details pane.
9. Open your SCIM bridge URL in a browser and enter your bearer token to test the bridge.
10. Update your identity provider configuration with the new bearer token.
    </details>