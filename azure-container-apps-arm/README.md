# Deploy 1Password SCIM Bridge on Azure Container Apps using the Azure Portal

_Learn how to deploy 1Password SCIM Bridge on the [Azure Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service._

This deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers): One for the SCIM bridge and another for Redis. There's also an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container. There are a few benefits to deploying 1Password SCIM Bridge on Azure Container Apps:

- **Low cost:** For standard deployments, the service will host your SCIM bridge for ~$16 USD/month (as of January 2024). Container Apps pricing is variable based on activity, and you can learn more on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- **Automatic DNS record management:** You don't need to manage a DNS record. Azure Container Apps automatically provides a unique one for your SCIM bridge domain.
- **Automatic TLS certificate management:** Azure Container Apps automatically handles TLS certificate management on your behalf.
- **Multiple deployment options:** The SCIM bridge can be deployed directly to Azure from the Portal using this guide or via the Azure Shell or command line tools in your local terminal using the [support guide](https://support.1password.com/scim-deploy-azure/). If you're using a custom deployment, cloning this repository is recommended.

## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md). You'll also need an Azure account with permission to create a Container App.

If you are using Google Workspace as your identity provider, follow [step 1](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) to create a Google service account, key, and API client. The json key file you downloaded will be your `workspace-credentials` in step 2 of this documentation.

> [!NOTE]
> If you don't have an Azure account, you can sign up for a free trial with starting credit: https://azure.microsoft.com/free/

## Step 1: Download the template file

1. Download the [ARM(Azure Resource Manager) template](./aca-op-scim-bridge-template.json) file using the download icon at the top right.

## Step 2: Create the Container App

1. Sign in to the Azure Portal and go to the [Deploy a custom template](https://portal.azure.com/#create/Microsoft.Template) page.
2. Click **Build your own template in the editor**.
3. Click **Load file** and upload the template file you downloaded earlier. Then click **Save**.
4. Fill out the following fields:
   - **Subscription** : Choose the subscription you prefer.
   - **Resource group**: Choose an existing Resource Group or create a new one using **Create new** button.
   - **Region**: Choose the region you prefer.
   - **Container App Name**: Enter a name you'd like to use, default will be `op-scim-con-app`.
   - **Container App Env Name**: Enter a name you'd like to use, default will be `op-scim-con-app-env`.
   - **Container App Log Analytics Name**: Enter a name you'd like to use, default will be `op-scim-con-app-log-analytics`.
   - **Scimsession** : Paste the entire contents of the `scimession` file.
   - **Workspace Actor** _(Only if you are using Google Workspace as your identity provider)_: Enter the email address of a Google Workspace administrator for the service account. If you are not using Google Workspace as your identity provider, leave this field blank.
   - **Workspace Credentials** _(Only if you are using Google Workspace as your identity provider)_: Paste the entire contents of the json key file you downloaded in the [before you begin](#before-you-begin) section. If you are not using Google Workspace as your identity provider, leave this field blank.
     > [!IMPORTANT]
     > The optional `Workspace Actor` and `Workspace Credentials` fields should only be filled if integrating with Google Workspace for automated provisioning.
5. Click **Review + create**.
6. Once the validation succeeds, click **Create**. It is expected to take a couple of minutes to complete the deployment.

## Step 3: Test your SCIM bridge

Once your deployment is complete, click **Go to resource group** and click on the container app you created.

To test if your SCIM bridge is online, choose **Overview** in your application's sidebar, then click your **Application Url** link. This is your **SCIM bridge URL**. Sign in using your bearer token to verify that your SCIM bridge is connected to your 1Password account.

## Step 4: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

> [!IMPORTANT]
> If you are using Google Workspace as your identity provider, you can skip this part. Once you sign in to your SCIM bridge using your bearer token as in step 3, you will see that your SCIM bridge is already connected to your Google Workspace account.

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
<summary>Replace your <code>scimsession</code> secret using the Azure Portal</summary>

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
