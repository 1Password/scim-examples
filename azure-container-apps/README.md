# Deploy 1Password SCIM Bridge on Azure Container Apps using the Azure Portal

_Learn how to deploy 1Password SCIM Bridge on the [Azure Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service._

This deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers): One for the SCIM bridge and another for Redis. There's also an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container. There are a few benefits to deploying 1Password SCIM Bridge on Azure Container Apps:

- **Low cost:** For standard deployments, the service will host your SCIM bridge for ~$16 USD/month (as of January 2024). Container Apps pricing is variable based on activity, and you can learn more on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- **Automatic DNS record management:** You don't need to manage a DNS record. Azure Container Apps automatically provides a unique one for your SCIM bridge domain.
- **Automatic TLS certificate management:** Azure Container Apps automatically handles TLS certificate management on your behalf.
- **Multiple deployment options:** The SCIM bridge can be deployed directly to Azure from the Portal using this guide or via the Azure Shell or command line tools in your local terminal using the [support guide](https://support.1password.com/scim-deploy-azure/). If you're using a custom deployment, cloning this repository is recommended.

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
   - **Container App Environment**: Choose an existing Container App environment or create a new one with the information in [step 1.1](#11-optional-create-a-new-container-app-environment).
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
   - **CPU and Memory**: Choose **0.25 CPU cores, 0.5 Gi memory**.
   - **Command override**: Enter `redis-server, --maxmemory 256mb, --maxmemory-policy volatile-lru, --save ""`
3. Click **Review + create** at the bottom of the page. When the page loads, click **Create.**

After the deployment is complete, click **Go to resource**, then continue to step 2.

## Step 2: Create a secret for your `scimsession` credentials

1. Choose **Secrets** from the Settings section in the sidebar.
2. Click **Add**, then enter `scimsession` in the Key field.
3. Paste the plain-text contents of the `scimession` file into the **Value** field.
4. Choose **Add**, then wait until the secret is created.

## Step 3: Deploy the SCIM bridge container

1. Choose **Containers** from the Application section in the sidebar.
2. Click **Edit and Deploy**.
3. Choose **Add** > **App container**.
4. Adjust the following:
   - **Name**: Enter `op-scim-bridge`.
   - **Image source**: Choose **Docker Hub or other registries**.
   - **Image and tag**: Enter `1password/scim:v2.9.13`.
   - **CPU cores**: Enter `0.25`
   - **Memory (Gi)**: Enter `0.5`.
5. Choose **Volume mounts** tab at the top of the 'Add a container' blade.
6. Click "Create new volume" below Secrets. Click **Ok** if it prompts 'your unsaved edits will be discarded'. Adjust the following:
   - **Volume type**: Choose Secret.
   - **Name**: Enter `credentials`.
   - **Mount all secrets:** should already be selected, but select it if is not.
7. Click **Add** to save the volume specification. You should see the new `credentials` volume listed under "Volume name".
8. Enter `/home/opuser/.op` in the **Mount path** field for this volume.
9. Click **Create**.

## Step 4: Enable ingress to your SCIM bridge

1. Wait for the notification that the revision deployment was successful, then choose **Ingress** from the Settings section in the sidebar.
2. Select **Enabled** to allow and configure ingress. Adjust the following:
   - **Ingress traffic**: Choose **Accepting traffic from anywhere**.
   - **Client certificate mode**: Choose **Ignore**.
   - **Target port**: Enter `3002`.
3. Click **Save**.

## Step 5: Test your SCIM bridge

To test if your SCIM bridge is online, choose **Overview** in your application's sidebar, then click your **Application Url** link. This is your **SCIM bridge URL**. Sign in using your bearer token to verify that your SCIM bridge is connected to your 1Password account.

## Step 6: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

### If Google Workspace is your identity provider

Follow the steps in this section to connect your SCIM bridge to Google Workspace.

<details>
<summary>Connect Google Workspace using the Azure Portal</summary>

#### 6.1: Get your Google Workspace service account key

Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).

#### 6.2: Download and edit the Google Workspace settings template

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) file from this repo.
2. Edit the following in this file:
   - **Actor**: Enter the email address of the Google Workspace administrator for the service account.
   - **Bridge Address**: Enter your SCIM bridge domain. This is the Application URL for your Container App, found on the overview page (**not** your 1Password account sign-in address). For example: `https://op-scim-bridge.example.eastus.azurecontainerapps.io`.
3. Save the file.

#### 6.3: Create secrets for Google Workspace

1. Open the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.
2. Choose **Secrets** from the Settings section in the sidebar.
3. Open the key file generated by Google for your service account you saved to your computer in [6.1](#61-get-your-google-workspace-service-account-key).
4. Click **Add** to create a secret for the credentials file, then fill out the following fields:
   - **Key**: Enter `workspace-credentials`.
   - **Value**: Copy the entire contents of the key file. Paste it into this field.
5. Click **Add**, then wait until the secret is created.
6. Open the settings file you edited in [6.2](#62-download-and-edit-the-google-workspace-settings-template).
7. Click **Add** to create another secret for the settings file, then fill out the following fields:
   - **Key**: Enter `workspace-settings`.
   - **Value**: Copy the entire contents of the settings file. Paste it into this field.
8. Click **Add**, then wait until the secret is created.

#### 6.4: Connect your SCIM bridge to Google Workspace

1. Choose **Containers** from the Application section in the sidebar.
2. Click **Edit and deploy**
3. Choose **Volumes**.
4. Click on the **credentials** volume listed to edit the volume.
5. Deselect **Mount all secrets**.
6. Under **Select individual secrets to mount**, you should see all three secrets that you created. Add `.json` to the **File path** for each of the Google Workspace secrets:
   - **workspace-credentials**: `workspace-credentials.json`
   - **workspace-settings**: `workspace-settings.json`
7. Click **Save**, then click **Create**.

</details>

<details>
<summary>Connect Google Workspace using the Azure Cloud Shell or AZ CLI</summary>

To connect Google Workspace using the Azure Cloud Shell or AZ CLI, follow the steps in our [Advanced guide](ADVANCED.md).

</details>

<hr>

## Update your SCIM bridge in the Azure Portal

> [!TIP]
> Check for 1Password SCIM Bridge updates on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).

1. Within your deployed 1Password SCIM Bridge Container App in the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Change the version number **2.9.13** in the **Image and Tag** field, **1password/scim:v2.9.13** to match the latest version from our [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updated image.
7. Enter your SCIM bridge URL in a browser and sign in with your bearer token.
8. Check the top left-hand side of the page to verify you're running the updated version of the SCIM bridge.

After you sign in to your SCIM bridge, the [Automated User Provisioning page](https://start.1password.com/integrations/active/) in your 1Password account will also update with the latest access time and SCIM bridge version.

## Get help

> [!TIP]
> For more advanced tips follow the Customize your Deployment, or Get Help section in our [Advanced guide](ADVANCED.md).

### How to update the **scimsession** secret

To use a new `scimsession` credentials file for your SCIM bridge, replace the secret in your Container App:

<details>
<summary>Replace your `scimsession` secret using the Azure Portal</summary>

1. Open the Azure Portal and go to the [Container Apps](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps) page.
2. Choose **Secrets** from the Settings section in the sidebar.
3. Edit the **scimsession** secret and paste the entire contents of your new `scimsession` file.
4. Select the checkbox and click **Save**.
5. Choose the **Revisions** from the Application section in the sidebar.
6. Click your current active revision and choose **Restart** in the details pane.
7. Enter your SCIM bridge URL in another browser tab or window and sign in using your new bearer token to [test your SCIM bridge](#step-5-test-your-scim-bridge).
8. Update your identity provider configuration with the new bearer token.
</details>

<details>
<summary>Replace your <code>scimsession</code> secret using the Azure Cloud Shell or AZ CLI</summary>

Using the Azure Cloud Shell or AZ CLI, follow the steps in our [Advanced guide](ADVANCED.md).

</details>
