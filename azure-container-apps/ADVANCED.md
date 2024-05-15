# Advanced details for 1Password SCIM Bridge on Azure Container Apps

_Learn how to deploy 1Password SCIM Bridge on the [Azure Container Apps](https://azure.microsoft.com/en-us/products/container-apps/#overview) service._

In this guide, you can learn about advanced customizations for the Azure Container App deployment of your SCIM bridge. There are a few benefits to deploying 1Password SCIM Bridge on Azure Container Apps:

- **Low cost:** For standard deployments, the service will host your SCIM bridge for ~$16 USD/month (as of January 2024). Container Apps pricing is variable based on activity, and you can learn more on [Microsoft's pricing page](https://azure.microsoft.com/en-us/pricing/details/container-apps/).
- **Automatic DNS record management:** You don't need to manage a DNS record. Azure Container Apps automatically provides a unique one for your SCIM bridge domain.
- **Automatic TLS certificate management:** Azure Container Apps automatically handles TLS certificate management on your behalf.
- **Multiple deployment options:** The SCIM bridge can be deployed directly to Azure from the Portal using [this guide](README.md) or via the Azure Shell or command line tools in your local terminal using the [support guide](https://support.1password.com/scim-deploy-azure/). If you're using a custom deployment, cloning this repository is recommended.

## Resource recommendations

The pod for 1Password SCIM Bridge should be vertically scaled if you provision a large number of users or groups. These are our default resource specifications and recommended configurations for provisioning at scale:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.25  | 0.5Gi  |
| High      | 1,000–5,000     | 0.5   | 1.0Gi  |
| Very high | >5,000          | 1.0   | 1.0Gi  |

If you're provisioning more than 1,000 users, update the resources assigned to the SCIM bridge container to follow these recommendations. The resources specified for the Redis container don't need to be adjusted.

> [!TIP]
> Learn more about [Container App Name (`ConAppName`) variable requirements](#container-app-name-requirements) that are referenced in the commands below. Copy the following command to a text editor and replace `$ConAppName` and `$ResourceGroup` with the names from your deployment similar to how you did originally in our [deployment guide](https://support.1password.com/scim-deploy-azure/#22-define-variables). 

<details>
<summary>Default deployment</summary>

If you're provisioning up to 1,000 users, run the following command to reset the specs back to the default:

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --cpu 0.25 --memory 0.5Gi
```

To update back to the defaults within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Set the **CPU cores** to `0.25` and the **Memory (Gi)** to `0.5`.
5. Click **Save**, then click **Create**.
</details>

<details>
<summary>High-volume deployment</summary>

If you're provisioning between 1,000 and 5,000 users, run the following command:

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --cpu 0.5 --memory 1.0Gi
```

To update the high-volume within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Set the **CPU cores** to `0.5` and the **Memory (Gi)** to `1.0`.
5. Click **Save**, then click **Create**.
</details>

<details>
<summary>Very high-volume deployment</summary>

If you're provisioning more than 5,000 users, run the following command:

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --cpu 1.0 --memory 1.0Gi
```

To update the very high-volume within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Set the **CPU cores** to `1.0` and the **Memory (Gi)** to `1.0`.
5. Click **Save**, then click **Create**.
</details>

## Customize your deployment

You can customize your 1Password SCIM Bridge deployment using some of the methods below.

> [!TIP]
> Copy the following commands to set certain environment variables, then define these variables to align to your deployment like you did in the [deployment guide](https://support.1password.com/scim-deploy-azure/#22-define-variables) before you run the commands.
> Alternatively you can add the environment variables through Azure Portal as detailed below.

<details>
<summary>Confirmation Interval</summary>

Use the OP_CONFIRMATION_INTERVAL environment variable to set how often the ConfirmationWatcher component runs in seconds. The minimum
interval is 30 seconds. If not set, the default value of 300 seconds (5 minutes) is used.

For example set `OP_CONFIRMATION_INTERVAL` to `30` to have the ConfirmationWatcher running every 30 seconds.

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_CONFIRMATION_INTERVAL=30
```

To update within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Add a new **Environment variable**, using the **name** of `OP_CONFIRMATION_INTERVAL`, the **source** of **Manual entry** and enter the time in seconds for the **value**
5. Click **Save**, then click **Create**.
</details>

<details>
<summary>Colorful logs</summary>

Use the OP_PRETTY_LOGS environment variable to set `OP_PRETTY_LOGS` to `1` to colorize container logs.

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_PRETTY_LOGS=1
```

To update within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Add a new **Environment variable**, using the **name** of `OP_PRETTY_LOGS`, the **source** of **Manual entry** and enter `1` for the **value**
5. Click **Save**, then click **Create**.
</details>

<details>
<summary>JSON logs</summary>

By default, container logs are output in a human-readable format. Set the environment variable `OP_JSON_LOGS` to `1` for newline-delimited JSON logs.

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_JSON_LOGS=1
```

To update within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Add a new **Environment variable**, using the **name** of `OP_JSON_LOGS`, the **source** of **Manual entry** and enter `1` for the **value**
5. Click **Save**, then click **Create**.

This can be useful for capturing structured logs.
</details>

<details>
<summary>Debug logs</summary>

Set the environment variable `OP_DEBUG` to `1` to enable debug level logging:

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_DEBUG=1
```

To update within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Add a new **Environment variable**, using the **name** of `OP_DEBUG`, the **source** of **Manual entry** and enter `1` for the **value**
5. Click **Save**, then click **Create**.

This may be useful for troubleshooting, or when contacting 1Password Support.
</details>

<details>
<summary>Trace logs</summary>

Set the environment variable `OP_TRACE` to `1` to enable trace level debug output in the logs:

```bash
az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --set-env-vars OP_TRACE=1
```

To update within the Azure Portal: 

1. Within Container App from the [Azure Container Apps Portal](https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.App%2FcontainerApps), select **Containers** from the sidebar.
2. Click **Edit and deploy**.
3. Select the checkbox next to your **op-scim-bridge** container, then choose **Edit**.
4. Add a new **Environment variable**, using the **name** of `OP_TRACE`, the **source** of **Manual entry** and enter `1` for the **value**
5. Click **Save**, then click **Create**.

This may be useful for troubleshooting issues.
</details>

## Update your SCIM bridge

> [!TIP]
> Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://releases.1password.com/provisioning/scim-bridge/).

For updating in the Azure Cloud Shell, follow the steps on our [Update 1Password SCIM Bridge guide](https://support.1password.com/scim-update/#azure-container-apps).

If you prefer to update through the Azure Portal > Container App blade, you can follow these steps: [Update your SCIM bridge in the Azure Portal](./README.md#update-your-scim-bridge-in-the-azure-portal)

After you sign in to your SCIM bridge, the [Automated User Provisioning page](https://start.1password.com/integrations/active/) in your 1Password account will also updated with the latest access time and SCIM bridge version.

## Get help

Here are some troubleshooting tips for your Azure Container Apps 1Password SCIM Bridge deployment.

### Region support

When you create or deploy the Container App Environment, Azure may present an error that the region isn't supported. You can review Azure documentation to make sure the region you selected supports [Azure Container Apps](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/?regions=all&products=container-apps).

### Container App working with multiple subscriptions

If you're using an existing resource group or have multiple subscriptions within your Azure Cloud environment, you may see errors stating that the subscription or the resource group cannot be found. Use the following command to set your subscription within your Shell. Alternatively you can add the `--subscription <subsciptionIDorName>` to every `az` command.
```
az account set --subscription <subsciptionIDorName>
```

### Container App Name requirements

Your Container App Name (the `ConAppName` variable) can contain lowercase letters, numbers, and hyphens. It must be 2 to 32 characters long, cannot start or end with a hyphen, and cannot start with a number. [Learn more about the naming rules and restrictions for Azure resources](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules#microsoftapp).

### View logs in Azure Container Apps

To view logs for your container app, click **Log Stream** on your environment or container app page. If you're having an issue deploying the SCIM bridge, review the `op-scim-bridge` container logs to identify the problem. Learn more about [viewing log streams](https://learn.microsoft.com/azure/container-apps/log-streaming?tabs=bash#view-log-streams-via-the-azure-portal)

### How to update the **scimsession** secret

After you download a new `scimsession` file, follow the steps below to replace the secret in your Container App.

Replace your <code>scimsession</code> secret using the Azure Cloud Shell or AZ CLI

> The following steps assume you have moved to mounting your secret from a volume mount and not using the base64 value in your secrets. 
> Follow the [command to update your deployment with the updated YAML file](https://support.1password.com/scim-deploy-azure/#step-3-set-up-and-deploy-1password-scim-bridge) to use volume mounts, redefining your variables as needed for this command to succeed. 


1. Open the [Azure Shell](https://shell.azure.com) or use the `az` CLI tool.

2. Copy and paste the following command, replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.

    - **Bash**:

        ```bash
        az containerapp secret set \
            --name $ConAppName \
            --resource-group $ResourceGroup \
            --secrets scimsession="$(cat $HOME/scimsession)"
        ```

    - **PowerShell**:

        ```pwsh
        az containerapp secret set `
            --name $ConAppName `
            --resource-group $ResourceGroup `
            --secrets scimsession="$(Get-Content $HOME/scimsession)"
        ```

3. Copy and paste the following command, which will have the `op-scim-bridge` container read the new secret. Replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, then run the command.
    ```bash
    az containerapp update -n $ConAppName -g $ResourceGroup --container-name op-scim-bridge --query properties.latestRevisionName
    ```

    Update the revsion name to use the output of the above command
    ```
    az containerapp revision restart -n $ConAppName -g $ResourceGroup --revision revisionName
    ```

4. Enter your SCIM Bridge URL in another browser tab or window and sign in using your new bearer token to [test your SCIM Bridge](./README.md#step-5-test-your-scim-bridge).

5. Update your identity provider configuration with the new bearer token.

## Appendix: If Google Workspace is your identity provider

Follow the steps in this section to connect your deployed Azure Container App SCIM bridge to Google Workspace.
Connect Google Workspace using the Azure Cloud Shell or AZ CLI. 
To connect Google Workspace using the Azure Portal interface, you can follow the steps on the [README](./README.md).

### Step 1: Get your Google service account key

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Open the [Azure Shell](https://shell.azure.com/) or open a new terminal window with the `az` CLI.
3. Upload your `workspace-credentials.json/<keyfile>` file to the Cloud Shell. Click the **Upload/Download files** button in your Cloud Shell and choose **Upload**.
4. Select the `<keyfile>.json` file that you saved to your computer. _It is recommended at this point to rename the file to `workspace-credentials.json` or make note of the filename to change the command used in [step 3](#step-3-create-your-google-workspace-secrets-and-update-your-scim-bridge-deployment)._
5. Make note of the upload destination, then click **Complete**.

### Step 2: Download and edit the `workspace-settings.json` file

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
    - **Actor**: Enter the email address of the Google Workspace administrator for the service account.
    - **Bridge Address**: Enter your SCIM bridge domain. This is the Application URL for your Container App, found on the overview page (not your 1Password account sign-in address). For example: `https://scim.example.com`. Ensure to leave the `https://` in the bridge address, and do not add any trailing `/` to your URL.
3. Save the file.

### Step 3: Create your Google Workspace secrets and update your SCIM bridge deployment

1. Copy and paste the following command for your shell, replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.
    - **Bash**:
    ```bash
    az containerapp secret set \
    --name $ConAppName \
    --resource-group $ResourceGroup \
    --secrets workspace-creds="$(cat $HOME/workspace-credentials.json)" workspace-settings="$(cat $HOME/workspace-settings.json)"
    ```
    - **PowerShell**:
    ```pwsh
    az containerapp secret set `
    --name $ConAppName `
    --resource-group $ResourceGroup `
    --secrets workspace-creds="$(Get-Content $HOME/workspace-credentials.json)" workspace-settings="$(Get-Content $HOME/workspace-settings.json)"
    ```
2. To update your SCIM bridge so it can use the new secrets, copy and paste the following command. Replace `$ConAppName` and `$ResourceGroup` with the names from your deployment, and run the command.
    - **Bash**:
    ```bash
    curl --silent --show-error https://raw.githubusercontent.com/1Password/scim-examples/main/azure-container-apps/google-workspace/aca-gw-op-scim-bridge.yaml |
    	az containerapp update --resource-group $ResourceGroup --name $ConAppName \
		--yaml /dev/stdin --query properties.configuration.ingress.fqdn
    ```
    - **PowerShell**:
    ```pwsh
    Invoke-RestMethod -Uri https://raw.githubusercontent.com/1Password/scim-examples/main/azure-container-apps/google-workspace/aca-gw-op-scim-bridge.yaml |
		az containerapp update --resource-group $ResourceGroup --name $ConAppName `
			--yaml /dev/stdin --query properties.configuration.ingress.fqdn
    ```
