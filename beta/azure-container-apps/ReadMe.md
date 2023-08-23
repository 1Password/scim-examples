# [Beta] Deploy 1Password SCIM Bridge on Azure Container Apps

This deployment example describes how to deploy 1Password SCIM Bridge as an app on Azure's [Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service.

The deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers), the SCIM bridge container and a Redis container and an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container.

## In this folder

- [`README.md`](./README.md): the document that you are reading.

## Overview

Deploying 1Password SCIM Bridge on Azure Container Apps comes with a few benefits:

- For standard deployments, Azure Container Apps will host your SCIM bridge for ~$16 USD/month (when this document was written)
  > **Note**
  >
  > Container Apps pricing is variable based on activity. Details can be found on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- No manual DNS record creation required. Azure Container Apps automatically provides a unique DNS record for your SCIM bridge URL.
- Azure Container Apps automatically handles TLS certificate management on your behalf.
- You will deploy 1Password SCIM Bridge directly to Azure from your Azure Portal or some commands can be performed from your local terminal. There is no requirement to clone this repository for this deployment.

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > **Note**
  >
  > Try 1Password Business free for 14 days: <https://start.1password.com/sign-up/business>
- An Azure account with permissions to create a Container App.
  > **Note**
  >
  > If you don't have a Azure account, you can sign up for a free trial with starting credit: <https://azure.microsoft.com/en-us/free/>
- [Azure CLI tool](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with the ContainerApp Extension or access to the [Azure Cloud Shell](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart) if performing the command driven deployment.

## Getting started

### Step 1: Generate credentials for automated user provisioning with 1Password

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. Click [Integrations](https://start.1password.com/integrations/directory) in the sidebar.
3. Choose your identity provider from the User Provisioning section.
4. Choose "Custom deployment".
5. Use the "Save in 1Password" buttons for both the `scimsession` file and `bearer token` to save them as items in your 1Password account. 
6. Use the download icon next to the `scimsession` file to save this file on your system.

## Deploy 1Password SCIM Bridge to Azure Container App

### Automatic Azure Deployment Steps using Azure CLI

Using the Azure Cloud Shell can be easier (the assumption for the commands below is that you are using the Cloud Shell), but this can also been done directly on your system with the Azure CLI tool with the ContainerApp Extension

Both methods need the Container App Extension added to the AZ tool of choice, using `az extension add --name containerapp --upgrade`

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com).
2. Define variables for the deployment using the following example in the Cloud Shell, _(using the bash or PowerShell syntax for the commands)_. Update the values in a text editor before pasting it into the terminal:
    - Using bash
    ```bash
    ResourceGroup="op-scim-bridge-rg"
    Location="canadacentral"
    ContainerAppEnvironment="op-scim-bridge-con-app-env"
    ContainerAppName="op-scim-bridge-con-app"
    ```
    - Using PowerShell 
    ```pwsh
    $ResourceGroup="op-scim-bridge-rg"
    $Location="canadacentral"
    $ContainerAppEnvironment="op-scim-bridge-con-app-env"
    $ContainerAppName="op-scim-bridge-con-app"
    ```

3. Create the resource group:

   ```
   az group create --name $ResourceGroup --location $Location
   ```

4. Create the Container App Environment:

   ```
   az containerapp env create --name $ContainerAppEnvironment --resource-group $ResourceGroup --location $Location
   ```

5. Upload your `scimsession` file to the Cloud Shell:
   - Click the “Upload/Download files” button and choose Upload.
   - Find the `scimsession` file that you saved to your computer and choose it.
   - Make a note of the upload destination, then click Complete.

6. Create the base Container App and Secret for your Base64-encoded `scimsession` credentials, _(using the bash or PowerShell syntax for the commands)_:
    - Using bash
    ```bash
    az containerapp create -n $ContainerAppName -g $ResourceGroup \
        --container-name op-scim-bridge \
        --image docker.io/1password/scim:v2.8.3 \
        --environment $ContainerAppEnvironment \
        --ingress external --target-port 3002 \
        --cpu 0.25 --memory 0.5Gi \
        --min-replicas 1 --max-replicas 1 \
        --secrets scimsession="$(cat /home/$USER/scimsession | base64)" \
        --env-vars OP_REDIS_URL="redis://localhost:6379" OP_SESSION=secretref:scimsession
    ```
    - Using PowerShell 
    ```pwsh
    az containerapp create -n $ContainerAppName -g $ResourceGroup `
    --container-name op-scim-bridge `
    --image docker.io/1password/scim:v2.8.3 `
    --environment $ContainerAppEnvironment `
    --ingress external --target-port 3002 `
    --cpu 0.25 --memory 0.5Gi `
    --min-replicas 1 --max-replicas 1 `
    --secrets scimsession="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path /home/$Env:USER/ 'scimsession'))) )" `
    --env-vars OP_REDIS_URL="redis://localhost:6379" OP_SESSION=secretref:scimsession
    ```

    > **Note**
    >
    > You may be prompted to install the ContainerApp extension with this message:
    >
    > ```bash
    > The command requires the extension containerapp. Do you want to install it now? The command will continue to run after the extension is installed. (Y/n):
    > ```
    >
    > The ContainerApp extension is required to deploy Container Apps from the command line. Type `Y` and press enter to install the extension.

7. Update your Container App to add the Redis container and get the fully qualified domain name to use as the URL for your SCIM bridge, _(using the bash or PowerShell syntax for the commands)_:
    - Using bash
    ```bash
    az containerapp update -n $ContainerAppName -g $ResourceGroup \
       --container-name op-scim-redis \
       --image docker.io/redis \
       --cpu 0.25 --memory 0.5Gi \
       --set-env-vars REDIS_ARGS="--maxmemory 256mb --maxmemory-policy volatile-lru" \
       --query properties.configuration.ingress.fqdn
    ```
    - Using PowerShell
    ```pwsh
    az containerapp update -n $ContainerAppName -g $ResourceGroup `
    --container-name op-scim-redis `
    --image docker.io/redis `
    --cpu 0.25 --memory 0.5Gi `
    --set-env-vars REDIS_ARGS="--maxmemory 256mb --maxmemory-policy volatile-lru" `
    --query properties.configuration.ingress.fqdn
    ```

8. Open the domain name listed in a separate browser tab to test your connection. You can sign in to your SCIM bridge using your bearer token.

### Step 3: Follow the steps to connect your Identity provider to the SCIM bridge.
 - [Connect your Identity Provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider)


<hr>

## Manual Azure Portal Deployment Steps

<details>
<summary> Manual Azure Portal Deployment Steps</summary>

### Step 1: Configure the `scimsession` credentials for passing to Container App

The `scimsession` credentials will be saved as a secret variable in Container App. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a plain-text file when you download them or save in 1Password during the setup.

> **Note**
    >
    >You will need to update the path to the scimsession file you download in the getting started section.

1. Get the Base64 encoded contents of your `scimsession` file, _(using the bash or PowerShell syntax for the commands)_: 
   
   - Using bash (Cloud Shell, macOS, or Linux):
     ```bash
     cat ./scimsession | base64
     ```
   - Using PowerShell (Cloud Shell, Windows, macOS, or Linux):
     ```pwsh
     [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path 'scimsession')))
     ```
   Copy the output value from the terminal to your clipboard. It will be needed to create the secret for the deployment.
2. Save the encoded value in your 1Password account for future use: 
   - Locate the "scimsession file" item in your 1Password account.
   - Click Edit.
   - Select "Add another field".
   - Select Password.
   - Rename the Password label above the value you just pasted, to something like `Base64 value`. 
   - Paste the Base64 value from your clipboard into the password field. 
   - Select **Save**.

### Step 2: Deploy your base SCIM bridge within Azure Container Apps

1. Create a new Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps).
2. Either use an existing Resource Group or select Create New under the **Resource Group** section.
3. Enter the **Container app name**, for example *op-scim-con-app*.
4. Select your **Region** for the deployment.
5. Either use the existing Container App Environment generated or select Create New under the **Container Apps Environment** Section.
    1. If creating a new Container App Environment, use a name that makes sense for your organization, for example op-scim-con-app-env.
    2. Leave **Consumption** selected, and **Zone Redundancy** disabled.
    3. Select **Create** on the create container apps environment window.
6. Select **Next : Container >** to continue the container app creation.
    1. Uncheck **Use quickstart image**.
    2. Change the name of the container to *op-scim-bridge*.
    3. Select **Docker Hub** for the image source.
    4. Enter `1password/scim:v2.8.3` for the **Image and Tag**.
    5. Leave the CPU and Memory as 0.25 CPU cores, 0.5 Gi memory.
    6. Add the following **Environment variables**:
        1. `OP_SESSION` currently with of `""` for now.
        2. `OP_REDIS_URL` with a value of `redis://localhost:6379`
7. Select **Next : Ingress >** to continue the container app creation.
    1. Enable the Ingress by checking the checkbox.
    2. Change the **Ingress Traffic** to Accepting traffic from anywhere.
    3. Specify the **Target Port** as **3002.**
8. Select **Review + create.**
9. Select **Create.**
10. Once the deployment is complete, select **Go to Resource**.

> **Note:** Expect the deployment to fail as it is expecting the second container to deploy successfully.

### Step 3: Finalize your SCIM bridge deployment to use your scimsession secret and add the Redis Container.

1. Within Azure Container App browser tab, Select **Secrets** along the left hand side.
    1. Select **Add**.
    2. Enter **scimsession** as the **Key field**.
    3. Enter the base64 value into the **Value** field. (This is what we added to your 1Password **scimsession file item** in the getting started section)
    4. Select **Add**.
    5. Allow the secret to finish creating.
2. Select **Containers** along the left hand side.
    1. Select **Edit and deploy** along the top.
    2. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
    3. Scroll down the the Environment variables and edit the **OP_SESSION** variable to have a **Source** of **Reference a secret** and for the **Value**, select the **scimsession** secret.
    4. Select **Save**.
    5. Select the **+ Add** button, selecting **App container**.
    6. Change the name of the container to **op-scim-redis**.
    7. Select **Docker Hub** for the image source.
    8. Enter **redis** for the **Image and Tag**.
    9. Change the CPU and Memory to 0.25 CPU cores, 0.5 Gi memory.
    10. Add the following **Environment variables**:
        1. `REDIS_ARGS` with value of `--maxmemory 256mb --maxmemory-policy volatile-lru`.
    11. Select **Add**.
    12. Select **Next : Scale >**.
    13. Drag both circles so the min and max are both set to 1.
    14. Select **Create**.
    15. Wait for the notification that the revision deployment was successful.
    16. Select **Overview**.
    17. On the right hand side, click on the Application Url (this is your SCIM bridge URL), to access and test your SCIM bridge.
    18. You should be prompted to log into the SCIM bridge with your `bearer token`.

### Step 4: Follow the steps to connect your Identity provider to the SCIM bridge.
 - [Connect your Identity Provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider)

</details>
<hr>

## Appendix

### Troubleshooting

Logs for a container app can be viewed from the **Log Stream**, there is a separate log stream for both containers of the revision that is active. Often reviewing the logs of the **op-scim-bridge** container can help understand any startup issues.
### Update 1Password SCIM Bridge

#### Update using the `az` CLI
The latest version of 1Password SCIM Bridge is posted on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website, where you can find details about the latest changes. 

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com).
2. Run the following command, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment. Also ensure to change the version number 2.8.3 to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
```az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge --image docker.io/1password/scim:v2.8.3```
3. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

#### Update using the Azure Portal

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), Select **Containers** from the left hand side.
2. Select **Edit and deploy** along the top.
3. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
4. Change the version number **2.8.3** in the **Image and Tag** field, **1password/scim:v2.8.3** to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updating image.
7. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

## TODO

Notes for future improvements to this deployment example:

- [ ] Add instructions for vertically scaling SCIM bridge for large-scale deployments
- [ ] Document Google Workspace credentials to be stored as secrets with deployment
