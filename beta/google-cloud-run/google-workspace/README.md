# Connect 1Password SCIM Bridge to Google Workspace

_Learn how to configure your 1Password SCIM Bridge deployed on [Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run) using the Cloud Shell._

> [!IMPORTANT]
> You must [deploy 1Password SCIM Bridge on Cloud Run](../README.md) before you can connect to Google Workspace.

## Step 1: Create a secret for Workspace credentials

1. Enable the Admin SDK API, create a service account named `onepassword-provisioning` and a secret named `workspace-credentials`, and add a secret version from a private key for the service account:

    ```sh
    gcloud services enable admin.googleapis.com &&
      gcloud secrets create workspace-credentials &&
      gcloud iam service-accounts keys create - --iam-account=$(
        gcloud iam service-accounts create onepassword-provisioning --format='value(email)'
      ) | gcloud secrets versions add workspace-credentials --data-file=-
    ```

2. Get the client ID of the service account:

    ```sh
    gcloud secrets versions access latest --secret=workspace-credentials | jq '.private_key_id' --raw-output
    ```

    Copy the client ID returned by this command to use in the next step.
3. In a separate browser tab or window, open the domain-wide delegation setup in the Workspace console: https://admin.google.com/ac/owl/domainwidedelegation. Click **Add new**, then fill out the information:
    - **Client ID**: paste the client ID for the service account key that is output by the last command.
    - **OAuth scopes**: paste this comma-separated list:

      ```sh
      https://www.googleapis.com/auth/admin.directory.user.readonly, https://www.googleapis.com/auth/admin.directory.group.readonly, https://www.googleapis.com/auth/admin.directory.group.member.readonly, https://www.googleapis.com/auth/admin.reports.audit.readonly
      ```

## Step 2: Download and edit the Workspace settings template

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) template file from this repository.
2. Edit the following in this file:
    - **Actor**: Enter the email address for a Google Workspace administrator to use with the service account.
    - **Bridge Address**: Enter your SCIM Bridge URL.
> [!IMPORTANT]
> This is the URL for the Cloud Run service from [Step 3: Deploy your SCIM Bridge](../README.md#step-3-deploy-your-scim-bridge)
> (_**not**_ your 1Password account sign-in address). For example: `https://op-scim-bridge-example-uc.a.run.app`.
3. Save the file.

## Step 3: Create a secret for Workspace settings

In the Cloud Console:

1. Click **⋮** _(More)_ > **Upload** in the Cloud Shell terminal menu bar.
2. Click **Choose Files**. Select the `workspace-settings.json` file that you saved to your computer.
3. Use the destination directory as is (or note the path if you saved it elsewhere). Click **Upload**.
4. Create the secret using the following command (replace `$HOME/workspace-settings.json` with the appropriate path if you saved it elsewhere):

    ```sh
    gcloud secrets create workspace-settings --data-file=$HOME/workspace-settings.json
    ```

## Step 4: Connect your SCIM Bridge to Google Workspace

1. Use the [`op-scim-bridge-gw.yaml`](./google-workspace/op-scim-bridge-gw.yaml) Cloud Run YAML from this repository to create a new revision of the service that is configured to connect to Google Workspace:

    ```sh
    curl --silent --show-error \
      https://raw.githubusercontent.com/1Password/scim-examples/beta/google-cloud-run/google-workspace/op-scim-bridge.yaml |
      gcloud run services replace - &&
      gcloud run services describe op-scim-bridge --format="value(status.url)"
    ```

2. Sign in to your SCIM Bridge in a web browser at the HTTPS endpoint provided by Cloud Run.
3. Select the Google group(s) you would like to assign to 1Password in the Google Workspace configuration. Click **Save**.

Learn more about automated provisioning in 1Password with Google Workspace: [Connect Google Workspace to 1Password SCIM Bridge (Next steps)](https://support.1password.com/scim-google-workspace/#next-steps).
