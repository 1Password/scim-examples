# Deploy 1Password SCIM Bridge on Azure Container Apps

This deployment example describes how to deploy 1Password SCIM Bridge as an app on Azure's [Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service.

The deployment consists of two [containers](https://learn.microsoft.com/en-us/azure/container-apps/containers), the SCIM bridge container and a Redis container and an [ingress](https://learn.microsoft.com/en-us/azure/container-apps/ingress-overview) for the SCIM bridge container.

## In this folder

- [`README.md`](./README.md): the document that you are reading.
- [`aca-op-scim-bridge.yaml`](./aca-op-scim-bridge.yaml): an Container App configuration file of a container app for the 1Password SCIM bridge.

**Table of contents:**

- [Standard Deployment](#standard-deployment)
- [Update your SCIM bridge](#update-1password-scim-bridge)
- [Resource recommendations](#resource-recommendations)
- [Connecting Google Workspace if it is your IdP](#if-google-workspace-is-your-identity-provider)
- [Troubleshooting](#Troubleshooting)

## Standard Deployment

Deploying 1Password SCIM Bridge on Azure Container Apps can be completed using our standard deployment guide. Any additional customizations can be applied from the resource recommendations as required for your deployment.

[Deploy 1Password SCIM Bridge on Azure Container Apps](https://support.1password.com/scim-deploy-azure/) using the standard deployment approach.

<details>
<summary>(Alternative) Azure Portal Deployment steps</summary>

If you can not use the Azure Cloud Shell (for example you do not have Storage tied to your Azure subscription) (or `az` CLI tools) or prefer to run through the configuration using the Azure Portal graphical interface you can follow the guide below. 

Following the standard deployment guide above allows you to deploy a 1Password SCIM Bridge in less steps. We would recommend reviewing the standard deployment guide (which also allows you to apply advanced configuration options) to see if it better fits your deployment needs.

### Step 1: Configure the `scimsession` credentials for passing to Container App

The `scimsession` credentials will be saved as a secret variable in Container App. These credentials have to be Base64-encoded to pass them into the environment, but they're saved as a plain-text file when you download them or save in 1Password during the setup.

> **Note:** You will need to update the path to the scimsession file you download in the getting started section.

1. Get the Base64 encoded contents of your `scimsession` file, _(using the bash or PowerShell syntax for the commands)_: 
   
   - Using Bash (Cloud Shell, macOS, or Linux):
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
    4. Enter `1password/scim:v2.9.0` for the **Image and Tag**.
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

## Update 1Password SCIM Bridge

#### Update using the Azure Cloud Shell or AZ CLI
The latest version of 1Password SCIM Bridge is posted on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website, where you can find details about the latest changes. 

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool.
2. Run the following command, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment. Also ensure to change the version number 2.9.0 to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).

    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --image docker.io/1password/scim:v2.9.0
    ```

3. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

#### Update using the Azure Portal

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), Select **Containers** from the left hand side.
2. Select **Edit and deploy** along the top.
3. Put a check in the box next to your **op-scim-bridge** container and select **Edit**.
4. Change the version number **2.9.0** in the **Image and Tag** field, **1password/scim:v2.9.0** to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save**.
6. Select **Create** to deploy a new revision using the updating image.
7. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

## Resource recommendations

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
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.25 --memory 0.5Gi
```

#### High volume deployment

For provisioning up to 5,000 users:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 0.5 --memory 1.0Gi
```

#### Very high volume

For provisioning more than 5,000 users:

```sh
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge \
  --cpu 1.0 --memory 1.0Gi
```

## If Google Workspace is your identity provider
<details>
<summary>Connect Google Workspace using the Azure Cloud Shell or AZ CLI</summary>
The following steps only apply if you use Google Workspace as your identity provider. If you use another identity provider, do not perform these steps.

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool..
3. Upload your `workspace-credentials.json`/`<keyfile>` file to the Cloud Shell:
   - Click the “Upload/Download files” button and choose Upload.
   - Find the `<keyfile>.json` file that you saved to your computer and choose it.
   - Make a note of the upload destination, then click Complete.
4. Obtain the `./google-workspace/workspace-settings.json`  file for editing: 
    Obtain the `workspace-settings.json` file: 
    - Using Bash
    ```bash
    curl https://raw.githubusercontent.com/1Password/scim-examples/solutions/main/azure-container-apps/google-workspace/workspace-settings.json --output workspace-settings.json --silent
    ```
     - Using PowerShell 
    ```pwsh
    Invoke-RestMethod -Uri `https://raw.githubusercontent.com/1Password/scim-examples/solutions/main/azure-container-apps/google-workspace/workspace-settings.json -OutFile workspace-settings.json
    ```
5. Edit the file in your editor of choice and fill in correct values for:
	* **Actor**: the email address of the administrator in Google Workspace that the service account is acting on behalf of.
	* **Bridge Address**: the URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is the Application URL for your Container App found on the overview page. For example: https://scim.example.com.
6. Run the following command, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment to create the workspace-credentials secret. 

    - Using Bash:
        ```bash
        az containerapp secret set \
            --name $ConAppName \
            --resource-group $ResourceGroup \
            --secrets workspace-creds="$(cat $HOME/workspace-credentials.json | base64)"
        ```

    - Using PowerShell:
        ```pwsh
        az containerapp secret set `
	        --name $ConAppName `
            --resource-group $ResourceGroup `
	        --secrets workspace-creds="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $HOME 'workspace-credentials.json'))))"
        ```

7. Run the following command, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment to create the workspace-credentials secret. 

    - Using Bash:
        ```bash
        az containerapp secret set \
            --name $ConAppName \
            --resource-group $ResourceGroup \
            --secrets workspace-settings="$(cat $HOME/workspace-settings.json | base64)"
        ```

    - Using PowerShell:
        ```pwsh
        az containerapp secret set `
	        --name $ConAppName `
            --resource-group $ResourceGroup `
	        --secrets workspace-settings="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $HOME 'workspace-settings.json'))))"
        ```

8. Restart the current revision to have the op-scim-bridge container read the new secret using the following commands, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment:
    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_WORKSPACE_CREDENTIALS=secretref:workspace-creds OP_WORKSPACE_SETTINGS=secretref:workspace-settings
    ```
</details>
<details>
<summary>Connect Google Workspace using the Azure Portal</summary>
The following steps only apply if you use Google Workspace as your identity provider. If you use another identity provider, do not perform these steps.

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Using the credential file you just downloaded, create a base64 value substitute `<keyfile>` with the filename generated by Google for your Google Service Account:
   - Using Bash:
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
   - Using Bash:
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

#### Region Support
When attempting to deploy or create the Container App Environment, Azure may present an error stating the region is not supported. Follow Azure documention to ensure the region name you defined, [supports Azure Container Apps](https://azure.microsoft.com/en-ca/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps).

#### Container App Name requirements
Your Container App Name, (the ConAppName variable) can contain lowercase letters, numerals, and hyphens. It must be between 2 and 32 characters long, and cannot start or end with a hyphen or cannot start with a number, it is recommended to check [Microsoft resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftapp) for any changes to the naming restrictions.

#### Viewing Logs in Azure Container Apps
Logs for a container app can be viewed from the **Log Stream**, there is a separate log stream for both containers of the revision that is active. Often reviewing the logs of the **op-scim-bridge** container can help understand any startup issues.

#### Replacing your `scimsession` secret in the deployment:

<details>
<summary>Replace your `scimsession` secret using the Azure Cloud Shell or AZ CLI</summary>

1. Start the Azure Cloud Shell from the navigation bar of your [Azure Portal](https://portal.azure.com) or directly open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool.
2. Run the following command, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment. 

    - Using Bash (Cloud Shell, macOS, or Linux):
        ```bash
        az containerapp secret set \
            --name $ConAppName \
            --resource-group $ResourceGroup \
            --secrets scimsession="$(cat $HOME/scimsession | base64)"
        ```

    - Using PowerShell (Cloud Shell, Windows, macOS, or Linux):
        ```pwsh
        az containerapp secret set `
	        --name $ConAppName `
            --resource-group $ResourceGroup `
	        --secrets scimsession="$([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $HOME 'scimsession'))))"
        ```

3. Restart the current revision to have the op-scim-bridge container read the new secret using the following commands, replacing `$ConAppName` and `$ResourceGroup` with the names from your deployment:
    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --query properties.latestRevisionName
    ```

    Update the revsion name to use the output of the above command
    ```
    az containerapp revision restart -n $ConAppName -g $ResourceGroup --revision revisionName
    ```

4. Test logging into your SCIM bridge URL with the new `bearer token`. 
5. Update your identity provider configuration with the new bearer token.
</details>

<details>
<summary>Replace your `scimsession` secret using the Azure Portal</summary>

1. Get the Base64 encoded contents of your newly downloaded `scimsession` file, _(using the bash or PowerShell syntax for the commands)_: 

    - Using Bash (Cloud Shell, macOS, or Linux):

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
