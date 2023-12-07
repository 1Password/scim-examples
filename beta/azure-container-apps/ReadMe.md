# Deploy 1Password SCIM Bridge on Azure Container Apps

This deployment example describes how to deploy 1Password SCIM Bridge as an app on Azure's [Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service.

The deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers), the SCIM bridge container and a Redis container and an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container.

## In this folder

- [`README.md`](./README.md): the document that you are reading.

**Table of contents:**

- [Overview](#Overview)
- [Prerequisites](#Prerequisites)
- [Getting Started: Generate credentials for automated user provisioning with 1Password](#Generate-credentials-for-automated-user-provisioning-with-1Password)
- [Azure Container App Deployment steps using Azure CLI](#Azure-Container-App-Deployment-Steps-using-Azure-CLI)
- [Azure Container App Deployment steps using the Azure Portal](#Azure-Portal-Deployment-Steps)
- [Appendix](#Appendix) - Resource recommendations & Google Workspace as your IdP
- [Troubleshooting](#Troubleshooting)
- [Update your SCIM bridge](#Update-1Password-SCIM-Bridge)

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

### Generate credentials for automated user provisioning with 1Password

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. Click [Integrations](https://start.1password.com/integrations/directory) in the sidebar.
3. Choose your identity provider from the User Provisioning section.
4. Choose "Custom deployment".
5. Use the "Save in 1Password" buttons for both the `scimsession` file and `bearer token` to save them as items in your 1Password account. 
6. Use the download icon next to the `scimsession` file to save this file on your system.

## Deploy 1Password SCIM Bridge to Azure Container App

### Azure Container App Deployment steps using Azure CLI

Using the Azure Cloud Shell can be easier (the assumption for the commands below is that you are using the Cloud Shell), but this can also been done directly on your system with the Azure CLI tool with the ContainerApp Extension

Both methods need the Container App Extension added to the AZ tool of choice, by running `az extension add --name containerapp --upgrade`

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com).
2. Add the Azure Container App extension by running the following command: `az extension add --name containerapp --upgrade`
3. Get a list of the available locations in your Azure account: `az account list-locations -o table`, verify that the region you want to deploy on [supports Azure Container Apps](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps), take note of the name field for the desired region. 
4. Define variables for the deployment using the following example in the Cloud Shell, _(using the bash or PowerShell syntax for the commands)_.

    > **Note**
    >
    >The ContainerAppName can contain lowercase letters, numerals, and hyphens. It must be between 2 and 32 characters long, and cannot start or end with a hyphen.
    > The location utilizes the name field of the az account list-locations command. 
    > Not all Azure locations support Conatiner Apps. See [supported regions for Azure Container Apps](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps)
    >

    Update the values in a text editor before pasting it into the terminal:

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
        --image docker.io/1password/scim:v2.8.4 \
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
    --image docker.io/1password/scim:v2.8.4 `
    --environment $ContainerAppEnvironment `
    --ingress external --target-port 3002 `
    --cpu 0.25 --memory 0.5Gi `
    --min-replicas 1 --max-replicas 1 `
    --secrets scimsession="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path /home/$Env:USER/ 'scimsession'))) )" `
    --env-vars OP_REDIS_URL="redis://localhost:6379" OP_SESSION=secretref:scimsession
    ```

    > **Note**
    >
    > You may be prompted to install the ContainerApp extension with this message if you did not previously install this extension:
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

### Follow the steps to connect your Identity provider to the SCIM bridge.
 - [Connect your Identity Provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider)


<hr>

## Azure Portal Deployment steps

<details>
<summary>Azure Portal Deployment steps</summary>

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
    4. Enter `1password/scim:v2.8.4` for the **Image and Tag**.
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
    3. Scroll down to the Environment variables and edit the **OP_SESSION** variable to have a **Source** of **Reference a secret** and for the **Value**, select the **scimsession** secret.
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

### Resource recommendations

The 1Password SCIM Bridge Pod should be vertically scaled when provisioning a large number of users or groups. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.25  | 0.5Gi  |
| High      | 1,000–5,000     | 0.5   | 1.0Gi  |
| Very high | >5,000          | 1.0   | 1.0Gi  |

If provisioning more than 1,000 users, the resources assigned to the SCIM bridge container should be updated as recommended in the above table. The resources specified for the Redis container do not need to be adjusted.

#### Default

To revert to the default specification that is suitable for provisioning up to 1,000 users:

```sh
az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.25 --memory 0.5Gi
```

#### High volume deployment

For provisioning up to 5,000 users:

```sh
az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.5 --memory 1.0Gi
```

#### Very high volume

For provisioning more than 5,000 users:

```sh
az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 1.0 --memory 1.0Gi
```

### If Google Workspace is your identity provider
<details>
<summary>Connect Google Workspace using the `az` CLI tool</summary>
The following steps only apply if you use Google Workspace as your identity provider. If you use another identity provider, do not perform these steps.

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com).
3. Upload your `workspace-credentials.json`/`<keyfile>` file to the Cloud Shell:
   - Click the “Upload/Download files” button and choose Upload.
   - Find the `<keyfile>.json` file that you saved to your computer and choose it.
   - Make a note of the upload destination, then click Complete.
4. Edit the file located at `./google-workspace/workspace-settings.json` and fill in correct values for:
	* **Actor**: the email address of the administrator in Google Workspace that the service account is acting on behalf of.
	* **Bridge Address**: the URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is the Application URL for your Container App found on the overview page. For example: https://scim.example.com.
5. Upload your `workspace-settings.json` file to the Cloud Shell:
   - Click the “Upload/Download files” button and choose Upload.
   - Find the `workspace-settings.json` file that you saved to your computer and choose it.
   - Make a note of the upload destination, then click Complete.
6. Run the following command, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment to create the workspace-credentials secret. 

    - Using bash:
        ```bash
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets workspace-creds="$(cat /home/$USER/workspace-credentials.json | base64)"
        ```

    - Using PowerShell:
        ```pwsh
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets workspace-creds="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path /home/$Env:USER/ 'workspace-credentials.json'))) )"
        ```

7. Run the following command, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment to create the workspace-credentials secret. 

    - Using bash:
        ```bash
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets workspace-settings="$(cat /home/$USER/workspace-settings.json | base64)"
        ```

    - Using PowerShell:
        ```pwsh
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets workspace-settings="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path /home/$Env:USER/ 'workspace-settings.json'))) )"
        ```

8. Restart the current revision to have the op-scim-bridge container read the new secret using the following commands, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment:
    ```bash
    az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_WORKSPACE_CREDENTIALS=secretref:workspace-creds OP_WORKSPACE_SETTINGS=secretref:workspace-settings
    ```
</details>
<details>
<summary>Connect Google Workspace using the Azure Portal</summary>
The following steps only apply if you use Google Workspace as your identity provider. If you use another identity provider, do not perform these steps.

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Using the credential file you just downloaded, create a base64 value substitute `<keyfile>` with the filename generated by Google for your Google Service Account:
   - Using bash:
     ```bash
     cat /path/to/<keyfile>.json | base64
     ```
   - Using PowerShell:
     ```pwsh
     [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path '/path/to/<keyfile>.json')))
     ```
3. Within [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Secrets** along the left hand side.
    1. Select **Add**.
    2. Enter **workspace-credentials** as the **Key field**.
    3. Enter the base64 value into the **Value** field.
    4. Select **Add**.
    5. Allow the secret to finish creating.  Add the OP_WORKSPACE_CREDENTIALS and OP_WORKSPACE_SETTINGS environment variables.
4. Edit the file located at `./google-workspace/workspace-settings.json` and fill in correct values for:
	* **Actor**: the email address of the administrator in Google Workspace that the service account is acting on behalf of.
	* **Bridge Address**: the URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is the Application URL for your Container App found on the overview page. For example: https://scim.example.com.
4. After you've edited the file, save it and create a base64 value from the settings file:
   - Using bash:
     ```bash
     cat /path/to/workspace-settings.json | base64
     ```
   - Using PowerShell:
     ```pwsh
     [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path '/path/to/workspace-settings.json')))
     ```
6. Within [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Secrets** along the left hand side.
    1. Select **Add**.
    2. Enter **workspace-settings** as the **Key field**.
    3. Enter the base64 value into the **Value** field.
    4. Select **Add**.
    5. Allow the secret to finish creating.  
7. Select **Containers** along the left hand side.
    1. Select **Edit and deploy** along the top.
    2. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
    3. In the Environment variables select and add a new variable, **OP_WORKSPACE_CREDENTIALS** to have a **Source** of **Reference a secret** and for the **Value**, select the **workspace-credentials** secret.
    4. Add a new second new variable, **OP_WORKSPACE_SETTINGS** to have a **Source** of **Reference a secret** and for the **Value**, select the **workspace-settings** secret.
    5. Select **Save**.
8. Select **Create** to scale the deployment to have it read the new secrets. 
</details>

## Troubleshooting

Logs for a container app can be viewed from the **Log Stream**, there is a separate log stream for both containers of the revision that is active. Often reviewing the logs of the **op-scim-bridge** container can help understand any startup issues.

#### Replacing your `scimsession` secret in the deployment:

<details>
<summary>Replace your `scimsession` secret using the `az` CLI</summary>

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com).
2. Run the following command, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment. 

    - Using bash (Cloud Shell, macOS, or Linux):
        ```bash
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets scimsession="$(cat /home/$USER/scimsession | base64)"
        ```

    - Using PowerShell (Cloud Shell, Windows, macOS, or Linux):
        ```pwsh
        az containerapp secret set -n $ContainerAppName -g $ResourceGroup --secrets scimsession="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path /home/$Env:USER/ 'scimsession'))) )"
        ```

3. Restart the current revision to have the op-scim-bridge container read the new secret using the following commands, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment:
    ```bash
    az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge --query properties.latestRevisionName
    ```

    Update the revsion name to use the output of the above command
    ```
    az containerapp revision restart -n $ContainerAppName -g $ResourceGroup --revision revisionName
    ```

4. Test logging into your SCIM bridge URL with the new `bearer token`. 
5. Update your identity provider configuration with the new bearer token.
</details>
<details>
<summary>Replace your `scimsession` secret using the Azure Portal</summary>

1. Get the Base64 encoded contents of your newly downloaded `scimsession` file, _(using the bash or PowerShell syntax for the commands)_: 

    - Using bash (Cloud Shell, macOS, or Linux):

        ```bash
        cat ./scimsession | base64
        ```

    - Using PowerShell (Cloud Shell, Windows, macOS, or Linux):

        ```pwsh
        [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path 'scimsession')))
        ```

    Copy the output value from the terminal to your clipboard. It will be needed to create the secret for the deployment.

2. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Secrets** from the sidebar on the left hand side. 
3. Edit the `scimsession` secret and paste the new value of your secret.
4. Select the checkbox and click **Save**.
5. Select the **Revisions** from the sidebar on the left hand side. 
6. Click your current active revision, select Restart along the top. 
7. Test logging into your SCIM bridge URL with the new `bearer token`.
8. Update your identity provider configuration with the new bearer token.
</details>

## Update 1Password SCIM Bridge

#### Update using the `az` CLI
The latest version of 1Password SCIM Bridge is posted on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website, where you can find details about the latest changes. 

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com).
2. Run the following command, replacing `$ContainerAppName` and `$ResourceGroup` with the names from your deployment. Also ensure to change the version number 2.8.4 to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
```az containerapp update -n $ContainerAppName -g $ResourceGroup --container-name op-scim-bridge --image docker.io/1password/scim:v2.8.4```
3. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

#### Update using the Azure Portal

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), Select **Containers** from the left hand side.
2. Select **Edit and deploy** along the top.
3. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
4. Change the version number **2.8.4** in the **Image and Tag** field, **1password/scim:v2.8.4** to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updating image.
7. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).
