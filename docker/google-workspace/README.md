# Connect 1Password SCIM Bridge to Google Workspace

_Learn how to configure your Docker deployed 1Password SCIM Bridge to connect Google Workspace._

This directory includes [a JSON template file](./workspace-settings.json) to configure Workspace settings, and a [Compose override file](./compose.gw.yaml) to create Docker secrets and merge the necessary configuration into your stack.

## Before you begin

To connect your SCIM bridge to Workspace, you'll need permissions in Google Cloud to enable the required APIs and create a service account, and the email addrress of an administrator with the required permissions to use the service account with your Workspace tenant.

## Step 1: Create a Google service account, key, and API client

1. Follow the directions in [Step 1](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) of our [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) support article.
> [!CAUTION]
> Complete **only** Step 1 in the linked article. If you sign in to the SCIM bridge to connect to Workspace, the
> configuration will be lost whenever the container is restarted. Follow the remaining steps in _this_ document to save
> the Workspace configuration in your deployment.
2. Upload the service account key to the working directory on the server. Make sure the file is named `workspace-credentials.json` on the server. For example, using SCP:

   ```sh
   scp ./op-scim-bridge-df05213c8cf1.json op-scim-bridge.example.com:scim-examples/docker/workspace-credentials.json
   ```

## Step 2: Configure Workspace settings

1. Download the [`workspace-settings.json`](./workspace-settings.json) template file from this repository to your computer.
2. Open the template in your favourite text editor. Edit the following in this file:
   - **Actor**: Enter the email address for a Google Workspace administrator to use with the service account.
   - **Bridge Address**: Enter your SCIM bridge URL.
> [!IMPORTANT]
> Your **SCIM bridge URL** is based on the fully qualified domain name of the DNS record created in [Before you
> begin](../README.md#before-you-begin). For example: `https://op-scim-bridge.example.com` (_not_ your 1Password account
> sign-in address).
3. Save the file and upload it to the working directory on the server. For example, using SCP:

   ```sh
   scp ./workspace-settings.json op-scim-bridge.example.com:scim-examples/docker/workspace-settings.json
   ```

## Step 4: Redeploy your SCIM bridge and select groups

1. Connect to the server and switch to the working directory. For example:

   ```sh
   cd ~/scim-examples/docker
   ```

2. Redeploy SCIM bridge with the `compose.gw.yaml` override file included in your deployment command to create Docker secrets from the uploaded files and merge the configuration needed to connect Workspace. For example, to merge Workspace into the base configuration:

   ```sh
   docker stack config \
     --compose-file ./compose.template.yaml \
     --compose-file ./google-workspace/compose.gw.yaml \
     | docker stack deploy --compose-file - op-scim-bridge
   ```

> [!NOTE]
> If you [customized your deployment](../README.md#advanced-configurations-and-customizations), include all override
> Compose files that you used in the deployment command as well as the Worskpace configuration. For example, to connect
> Workspace to a SCIM bridge deployed behind [an externally managed load balancer or reverse
> proxy](../README.md#external-load-balancer-or-reverse-proxy):
>
> ```sh
> docker stack config \
>   --compose-file ./compose.template.yaml \
>   --compose-file ./compose.http.yaml \
>   --compose-file ./google-workspace/compose.gw.yaml \
>   | docker stack deploy --compose-file - op-scim-bridge
> ```

3. Access your SCIM bridge URL in a web browser. Sign in with your bearer token.
4. Select the Google group(s) you want to provision to 1Password in the Google Workspace configuration section. Click Save.

Learn more about automated provisioning with Google Workspace: [Connect Google Workspace to 1Password SCIM Bridge (Next steps)](https://support.1password.com/scim-google-workspace/#next-steps).
