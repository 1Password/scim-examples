# Deploy 1Password SCIM Bridge on Google Cloud Run

_Learn how to deploy 1Password SCIM Bridge on [Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run) using the Cloud Shell in Google Cloud._

This guide can be used to deploy 1Password SCIM Bridge as an ingress container to a single replica [Cloud Run service](https://cloud.google.com/run/docs/overview/what-is-cloud-run#services) with the required Redis cache deployed as a sidecar container. Credentials are stored in Secret Manager and mounted as volumes attached to the SCIM Bridge container.

The included [Cloud Run service YAML](https://cloud.google.com/run/docs/reference/yaml/v1#service) manifests are suitable for use in a production environment without modification, but are intentionally minimal for simplicity, to allow any identity provider to connect to its public endpoint, and to facilitate its use as a base for a customized deployment.

*Table of contents:*

- [Before you begin](#before-you-begin)

<!-- !TODO: Complete ToC  -->

## Before you begin

<!-- !TODO: Document prereqs  -->

## Step 1: Set up Google Cloud

1. Create a [project](https://cloud.google.com/docs/overview#projects) to organize the Google Cloud resources for your 1Password SCIM Bridge deployment, and set it as the default project for your Cloud Shell environment:

    ```sh
    gcloud projects create op-scim-bridge --set-as-default
    ```

> [!TIP]
> If you have already created a project for SCIM Bridge, set it as the default project for this Cloud Shell session. For example:
>
> ```sh
> gcloud config set project op-scim-bridge
> ```

2. Enable the Secret Manager and Cloud Run APIs for your project:

    ```sh
    gcloud services enable secretmanager.googleapis.com run.googleapis.com
    ```

3. Set the default region for Cloud Shell:

    ```sh
    gcloud config set compute/region us-central1
    ```

> [!NOTE]
> All region-bound resources created in the following steps will be created in the specified region. You may replace `us-central1` in the above commmand with your preferred region.

## Step 2: Create a secret for your `scimsession` credentials

The Cloud Run service for SCIM Bridge will be configured to mount volume using a secret from Secret Manager. Follow these steps to upload your `scimsession` credentials file to the Cloud Shell, create a secret, and store the file contents as its first secret version:

1. Click **⋮** _(More)_ > **Upload** in the Cloud Shell terminal menu bar.
2. Click **Choose Files**. Select the `scimsession` file that you saved to your computer.
3. Use the suggested destination directory. Click **Upload**.

> [!NOTE]
> If the file is saved to a different directory or using a different file name, make a note of the full path to
> the file.

4. Create a secret with the contents of this file as its first secret version using the following command:

    ```sh
    gcloud secrets create scimsession --data-file=$HOME/scimsession
    ```

> [!TIP]
> The command above is expected work as is if the file is named `scimsession` and if it was saved to the home
> directory when uploading the file. If not, replace `$HOME/scimsession` with the actual path to the file. For
> example:
>
> ```sh
> gcloud secrets create scimsession --data-file=/example/path/to/scimsession.file
> ```

5. Enable Cloud Run to access the secret using the Compute Engine default service account for the project:

    ```sh
    gcloud secrets add-iam-policy-binding scimsession \
      --member=serviceAccount:$(
        gcloud iam service-accounts list --filter="$(
          gcloud projects describe op-scim-bridge --format="value(projectNumber)"
        )-compute@developer.gserviceaccount.com" --format="value(email)"
      )
      --role=roles/secretmanager.secretAccessor
    ```

## Step 3: Deploy your SCIM Bridge

Run this command to stream [`op-scim-bridge.yaml`](./op-scim-bridge.yaml) Cloud Run service YAML from this repository, use it to deploy SCIM Bridge inline, and enable public ingress for your SCIM Bridge so that you and your identity provider can connect to its public endpoint:

```sh
curl --silent --show-error \
  https://raw.githubusercontent.com/1Password/scim-examples/solutions/pike/google-cloud-run/beta/google-cloud-run/op-scim-bridge.yaml |
  gcloud run services replace - &&
  gcloud run services add-iam-policy-binding op-scim-bridge --member=allUsers --role=roles/run.invoker &&
  gcloud run services describe op-scim-bridge --format="value(status.url)"
```

<!-- !TODO: Replace the URL above with the link to its path when it is merged into main.
```sh
curl --silent --show-error \
  https://raw.githubusercontent.com/1Password/scim-examples/main/beta/google-cloud-run/op-scim-bridge.yaml |
  gcloud run services replace - &&
  gcloud run services add-iam-policy-binding op-scim-bridge --member=allUsers --role=roles/run.invoker
```
-->

The final line of the above chained command should output a URL for the HTTPS endpoint provded by Cloud Run. This is your **SCIM Bridge URL**.

## Step 4: Test your SCIM bridge

Use your SCIM Bridge URL to test the connection and view status information. For example:

```sh
curl --silent --show-error --request GET --header "Accept: application/json" \
  --header "Authorization: Bearer mF_9.B5f-4.1JqM" \
  https://op-scim-bridge-example-uc.a.run.app/health
```

Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://op-scim-bridge-example-uc.a.run.app` with your SCIM Bridge URL.

<details>
<summary>Example JSON response:</summary>

> ```json
> {
>   "build": "209031",
>   "version": "2.9.3",
>   "reports": [
>     {
>       "source": "ConfirmationWatcher",
>       "time": "2024-04-25T14:06:09Z",
>       "expires": "2024-04-25T14:16:09Z",
>       "state": "healthy"
>     },
>     {
>       "source": "RedisCache",
>       "time": "2024-04-25T14:06:09Z",
>       "expires": "2024-04-25T14:16:09Z",
>       "state": "healthy"
>     },
>     {
>       "source": "SCIMServer",
>       "time": "2024-04-25T14:06:56Z",
>       "expires": "2024-04-25T14:16:56Z",
>       "state": "healthy"
>     },
>     {
>       "source": "StartProvisionWatcher",
>       "time": "2024-04-25T14:06:09Z",
>       "expires": "2024-04-25T14:16:09Z",
>       "state": "healthy"
>     }
>   ],
>   "retrievedAt": "2024-04-25T14:06:56Z"
> }
> ```

</details>
<br />

Similar information is presented graphically by accessing your SCIM Bridge URL in a web browser. Sign in with your bearer token to view status information and download container log files.

## Step 5: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to your SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

### If Google Worskpace is your identity provider

> [!IMPORTANT]
> Additional steps are required to enable automated provisioning with Workspace.

The [`google-workspace` subfolder](./google-workspace/) in this directory includes [a template JSON file](./google-workspace/workspace-settings.json) used to configure the connection to Workspace, and [a Cloud Run YAML](./google-workspace/op-scim-bridge-gw.yaml) that mounts the secrets required to synchronize with Workspace for provisioning.

<details>
<summary>Expand to learn how to connect to Workspace:</summary>

### Configure SCIM Bridge to connect to Google Workspace

Follow the steps in this section to connect your SCIM Bridge to Google Workspace.

#### 5.1: Create a secret for Workspace credentials

<!-- !TODO: Translate these steps to CLI: [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client). -->

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

#### 5.2: Download and edit the Workspace settings template

1. Download the [`workspace-settings.json`](./google-workspace/workspace-settings.json) template file from this repository.
2. Edit the following in this file:
    - **Actor**: Enter the email address for a Google Workspace administrator to use with the service account.
    - **Bridge Address**: Enter your SCIM Bridge URL.
> [!IMPORTANT]
> This is the URL for the Cloud Run service from [Step 3: Deploy your SCIM Bridge](#step-3-deploy-your-scim-bridge)
> (_**not**_ your 1Password account sign-in address). For example: `https://op-scim-bridge-example-uc.a.run.app`.
3. Save the file.

#### 5.3: Create a secret for Workspace settings

In the Cloud Console:

1. Click **⋮** _(More)_ > **Upload** in the Cloud Shell terminal menu bar.
2. Click **Choose Files**. Select the `workspace-settings.json` file that you saved to your computer.
3. Use the destination directory as is (or note the path if you saved it elsewhere). Click **Upload**.
4. Create the secret using the following command (replace `$HOME/workspace-settings.json` with the appropriate path if you saved it elsewhere):

    ```sh
    gcloud secrets create workspace-settings --data-file=$HOME/workspace-settings.json
    ```

#### 4.4: Connect your SCIM Bridge to Google Workspace

1. Use the [`op-scim-bridge-gw.yaml`](./google-workspace/op-scim-bridge-gw.yaml) Cloud Run YAML from this repository to create a new revision of the service that is configured to connect to Google Workspace:

    ```sh
    curl --silent --show-error \
      https://raw.githubusercontent.com/1Password/scim-examples/beta/google-cloud-run/google-workspace/op-scim-bridge.yaml |
      gcloud run services replace - &&
      gcloud run services describe op-scim-bridge --format="value(status.url)"
    ```

2. Sign in to your SCIM Bridge in a web browser at the HTTPS endpoint provided by Cloud Run.
3. Select the Google group(s) you would like to assign to 1Password in the Google Workspace configuration. Click **Save**.

Learn more about automated provisioning in 1Password with Google Workspace:

</details>

<!-- Collecting references that may be relevant to document and possibly hyperlinked somewhere above.

## References

- <https://cloud.google.com/iam/docs/keys-create-delete?hl=en#required-permissions>
- <https://cloud.google.com/run/docs/reference/yaml/v1#service>
- <https://cloud.google.com/secret-manager/docs/create-secret-quickstart#gcloud>
- <https://cloud.google.com/shell/docs/uploading-and-downloading-files>
- <https://cloud.google.com/secret-manager/docs/manage-access-to-secrets#required_roles>
-->
