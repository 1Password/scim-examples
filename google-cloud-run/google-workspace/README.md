# Connect 1Password SCIM Bridge to Google Workspace

_Learn how to configure your 1Password SCIM Bridge deployed on [Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run) to connect to Google Workspace using Cloud Shell._

This directory includes [a template JSON file](./workspace-settings.json) used to configure the connection to Workspace and [a Cloud Run YAML](./op-scim-bridge-gw.yaml) that includes the additional configuration required by Cloud Run.

## Before you begin

> [!IMPORTANT]
> Complete the steps to [deploy 1Password SCIM Bridge on Cloud Run](../README.md) **before** the next steps in this guide.

 To connect your SCIM bridge to Workspace, you'll need permissions in Google Cloud to enable the required APIs, create a service account, and an administrator with the required permissions to use the service account with your Workspace tenant.

## Step 1: Create a secret for Workspace credentials

1. Sign in to the Google Cloud console and activate Cloud Shell: <https://console.cloud.google.com?cloudshell=true>
2. Enable the Admin SDK API, create a service account named `onepassword-provisioning` and a secret named `workspace-credentials`, add a secret version from a private key for the service account, and enable Cloud Run to access it using the Compute Engine default service account for the project:

    ```sh
    gcloud services enable admin.googleapis.com &&
      gcloud secrets create workspace-credentials &&
      gcloud iam service-accounts keys create - --iam-account=$(
        gcloud iam service-accounts create onepassword-provisioning --format='value(email)'
      ) | gcloud secrets versions add workspace-credentials --data-file=- &&
      gcloud secrets add-iam-policy-binding workspace-credentials --member=serviceAccount:$(
        gcloud iam service-accounts list --filter="$(
          gcloud projects describe $(gcloud config get-value project) --format='value(projectNumber)'
        )-compute@developer.gserviceaccount.com" --format="value(email)"
      ) --role=roles/secretmanager.secretAccessor
    ```

3. Get the client ID of the service account:

    ```sh
    gcloud secrets versions access latest --secret=workspace-credentials | jq '.client_id' --raw-output
    ```

    Copy the client ID returned by this command to use in the next step.
4. In a separate browser tab or window, open the domain-wide delegation setup in the Workspace console: <https://admin.google.com/ac/owl/domainwidedelegation>. Click **Add new**, then fill out the information:
    - **Client ID**: paste the client ID for the service account key copied to your clipboard in the previous step.
    - **OAuth scopes**: copy and paste this comma-separated list:

      ```text
      https://www.googleapis.com/auth/admin.directory.user.readonly, https://www.googleapis.com/auth/admin.directory.group.readonly, https://www.googleapis.com/auth/admin.directory.group.member.readonly, https://www.googleapis.com/auth/admin.reports.audit.readonly
      ```

## Step 2: Download and edit the Workspace settings template

1. Download the [`workspace-settings.json`](./workspace-settings.json) template file from this repository.
2. Edit the following in this file:
    - **Actor**: Enter the email address for a Google Workspace administrator to use with the service account.
    - **Bridge Address**: Enter your SCIM bridge URL.
> [!IMPORTANT]
> This is the URL for the Cloud Run service from [Step 3: Deploy your SCIM bridge](../README.md#step-3-deploy-your-scim-bridge)
> (_**not**_ your 1Password account sign-in address). For example: `https://op-scim-bridge-example-uc.a.run.app`.
3. Save the file.

## Step 3: Create a secret for Workspace settings

In the Cloud Console:

1. Click **⋮** _(More)_ > **Upload** in the Cloud Shell terminal menu bar.
2. Click **Choose Files**. Select the `workspace-settings.json` file that you saved to your computer.
3. Use the destination directory as is (or note the path if you saved it elsewhere). Click **Upload**.
4. Create a secret from the file:

    ```sh
    gcloud secrets create workspace-settings --data-file=$HOME/workspace-settings.json
    ```

> [!TIP]
> If the file was not saved using the suggested values, replace `$HOME/workspace-settings.json` with the actual path to
> the file. For example:
>
> ```sh
> gcloud secrets create workspace-settings --data-file=/example/path/to/workspace-settings.file
> ```

5. Enable Cloud Run to access the secret using the Compute Engine default service account for the project:

    ```sh
    gcloud secrets add-iam-policy-binding workspace-settings --member=serviceAccount:$(
      gcloud iam service-accounts list --filter="$(
        gcloud projects describe $(gcloud config get-value project) --format='value(projectNumber)'
      )-compute@developer.gserviceaccount.com" --format="value(email)"
    ) --role=roles/secretmanager.secretAccessor
    ```

## Step 4: Redeploy your SCIM bridge to connect to Workspace

1. Use the [`op-scim-bridge-gw.yaml`](./op-scim-bridge-gw.yaml) Cloud Run YAML from this repository to create a new revision of the service that is configured to connect to Google Workspace:

    ```sh
    curl --silent --show-error \
      https://raw.githubusercontent.com/1Password/scim-examples/main/google-cloud-run/google-workspace/op-scim-bridge-gw.yaml |
      gcloud run services replace - &&
      gcloud run services describe op-scim-bridge --format="value(status.url)"
    ```

2. Sign in to your SCIM bridge in a web browser at the HTTPS endpoint provided by Cloud Run.
3. Select the Google group(s) you would like to assign to 1Password in the Google Workspace configuration. Click **Save**.

Learn more about automated provisioning in 1Password with Google Workspace: [Connect Google Workspace to 1Password SCIM Bridge (Next steps)](https://support.1password.com/scim-google-workspace/#next-steps).

## Update your SCIM bridge when Google Workspace is your IdP

1. Sign in to the Google Cloud console and activate Cloud Shell: <https://console.cloud.google.com?cloudshell=true>

2. Create a new revision of your SCIM bridge deployment using the latest version of the [`op-scim-bridge-gw.yaml`](./op-scim-bridge-gw.yaml) Cloud Run services YAML from this directory in our repository:

    ```sh
    curl --silent --show-error \
      https://raw.githubusercontent.com/1Password/scim-examples/main/google-cloud-run/google-workspace/op-scim-bridge-gw.yaml |
      gcloud run services replace -
    ```

> [!TIP]
> Check for 1Password SCIM Bridge updates on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).
3. [Test your SCIM bridge deployment](../README.md#step-4-test-your-scim-bridge) using your bearer token.

The new version number that you updated to should appear in the health check, the container logs for 1Password SCIM Bridge, and the top left-hand side of the page if signing in to the SCIM bridge at its URL in a web browser. After you sign in to your SCIM bridge, the [Automated User Provisioning page](https://start.1password.com/integrations/provisioning/) in your 1Password account will also update with the latest access time and SCIM bridge version.
