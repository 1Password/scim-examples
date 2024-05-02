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

> [!IMPORTANT]
> Additional steps are required to enable automated provisioning with Google Workspace. The [`google-workspace` subfolder](./google-workspace/) in this directory includes [a template JSON file](./google-workspace/workspace-settings.json) used to configure the connection to Workspace, [a Cloud Run YAML](./google-workspace/op-scim-bridge-gw.yaml) that includes the additional configuration required by Cloud Run.
>
> Learn how: [Connect 1Password SCIM Bridge to Google Workspace](./google-workspace/README.md)

To finish setting up automated user provisioning, [connect your identity provider to your SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

<!-- Collecting references that may be relevant to document and possibly hyperlinked somewhere above.

## References

- <https://cloud.google.com/iam/docs/keys-create-delete?hl=en#required-permissions>
- <https://cloud.google.com/run/docs/reference/yaml/v1#service>
- <https://cloud.google.com/secret-manager/docs/create-secret-quickstart#gcloud>
- <https://cloud.google.com/shell/docs/uploading-and-downloading-files>
- <https://cloud.google.com/secret-manager/docs/manage-access-to-secrets#required_roles>
-->