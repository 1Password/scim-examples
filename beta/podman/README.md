# [Beta] Deploy 1Password SCIM Bridge using Podman

This example describes how to deploy 1Password SCIM Bridge using [Podman](https://podman.io/) and [Podman-compose](https://github.com/containers/podman-compose). The deployment includes two containers, one each for the SCIM bridge container and the required Redis cache. This deployment is recommended for users who can only use Red Hat Enterprise Linux (RHEL) VM for their on-prem deployment since Docker will have issues running on these VMs.
Podman-compose is a community developed package that enables Podman to achieve the same functionality as Docker Compose. It allows users to specify all the necessary details inside a single file.

> **Before you move on**
>
> If you are using Google Workspace or need to send more than 1000 provisioning requests at a time, please reach out to 1Password support team as these are not supported with Podman deployment yet.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`podman.template.yaml`](./compose.template.yaml): a [Compose Specification](https://docs.docker.com/compose/compose-file/) format compose file for 1Password SCIM Bridge.
- [`podman.gw.yaml`](./compose.gw.yaml): an override configuration to merge the configuration necessary for customers integrating with Google Workspace.
- [`podman.http.yaml`](./compose.http.yaml): optional configuration for exposing an HTTP port on the Podman host for forwarding plain-text traffic within a private network from a public TLS termination endpoint
- [`podman.tls.yaml`](./compose.http.yaml): optional configuration for enabling a self-managed TLS certificate
- [`scim.env`](./scim.env): an environment file used to customize the SCIM bridge configuration

## Prerequisites

> **Note**
>
> 📚 Before proceeding, review the [Preparation Guide](/PREPARATION.md) at the root of this repository.

- AMD64/ARM64 VM or bare metal server with a Podman-supported Linux distribution (usually RHEL)
- Create a public DNS A record that points to the public IP address of the Linux server for your SCIM bridge. For example, `scim.example.com`.
- SSH access to the Linux server

## Get started
### 🛠️ Install Podman and Podman-compose

On the Linux machine that you will be using as the Podman host for your SCIM bridge:

1. [Install Podman](https://podman.io/docs/installation) on the Linux server.
2. [Install podman-compose](https://github.com/containers/podman-compose?tab=readme-ov-file#installation) on the Linux server. 
> **`sudo dnf install podman-compose` not working?**
>
> Dnf package manager may be missing some python libraries including podman-compose on some versions of VMs. If that's the case, run `pip3 install podman-compose`.

### 👨‍💻 Start the deployment

All following steps should be run on the same computer where you are already using 1Password, or another machine that can access the Linux server using SSH and has access to the `scimsession` file from the integration setup:

1. Open your preferred terminal. Clone this repository and switch to this directory:

   ```sh
   git clone https://github.com/1Password/scim-examples.git
   cd ./scim-examples/beta/podman
   ```

2. Run the commands below to make the shell script files executable.

  ```sh
  chmod u+x deploy.sh
  chmod u+x teardown.sh
  ```

3. Save the `scimsession` credentials file from [the Automated User Provisioning setup](https://start.1password.com/integrations/directory/) to this working directory.
Once this is done, you should be able to see `scimsession` listed when you run `ls`.


4. Run the `deploy.sh` script by using the command below.

> **Warning**
>
> ⏩ If you're using Google Workspace for automated user provisioning, 
> skip this step and move to the section below
  
  ```sh
  ./deploy.sh --file podman.http.yaml
  ```
  
  Continue from [Test your SCIM bridge](#test-your-scim-bridge).

### If you're using Google Workspace as your IdP
Additional configuration and credentials are required to integrate your 1Password account with Google Workspace.

> **Warning**
>
> ⏩ This section is **only** for customers who are integrating 1Password with Google Workspace for automated user
> provisioning. If you are _not_ integrating with Workspace, skip the steps in this section and
> [Test your SCIM bridge](#test-your-scim-bridge)

See [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) for instructions to create the service account, key, and API client.

1. Save the Google Workspace service account key to the working directory.
2. Make sure the service account key is named `workspace-credentials.json`.
3. Open the [`workspace-settings.json`](./workspace-settings.json) file in a text editor and replace the values for each key:

   - `actor`: the email address for the administrator that the service account is acting on behalf of
   - `bridgeAddress`: the URL for your SCIM bridge based on the fully qualified domain name of the DNS record created in [Get started](#get-started)

   ```json
   {
     "actor": "admin@example.com",
     "bridgeAddress": "https://scim.example.com"
   }
   ```

4. Open `scim.env` in your favourite text editor. Uncomment `OP_WORKSPACE_CREDENTIALS` and `OP_WORKSPACE_SETTINGS` in the last paragraph of the file.

  ```dotenv
  ...
  # (GOOGLE WORKSPACE) the options below are intended for users of our Google Workspace integration
  # OP_WORKSPACE_CREDENTIALS should be base64-encoded Google Service Account credentials JSON
  OP_WORKSPACE_CREDENTIALS=/run/secrets/workspace-credentials
  # OP_WORKSPACE_SETTINGS is a base64-encoded string containing Workspace settings JSON for your bridge
  OP_WORKSPACE_SETTINGS=/run/secrets/workspace-settings
  ...
  ```

5. Run the `deploy.sh` script by using the command below

  ```sh
  ./deploy.sh --file podman.http.yaml --file podman.gw.yaml
  ```


## Test your SCIM bridge

Run this command to view logs from the service for the SCIM bridge container:

```sh
podman logs scim
```

Your **SCIM bridge URL** is based on the fully qualified domain name of the DNS record created in [Get started](#get-started). For example: `https://scim.example.com`. Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://scim.example.com` with your SCIM bridge URL to test the connection and view status information.

```sh
curl --silent --show-error --request GET --header "Accept: application/json" \
  --header "Authorization: Bearer mF_9.B5f-4.1JqM" \
  https:/scim.example.com/health
```

<details>
<summary>Example JSON response:</summary>

```json
{
  "build": "209031",
  "version": "2.9.3",
  "reports": [
    {
      "source": "ConfirmationWatcher",
      "time": "2024-04-25T14:06:09Z",
      "expires": "2024-04-25T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "RedisCache",
      "time": "2024-04-25T14:06:09Z",
      "expires": "2024-04-25T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "SCIMServer",
      "time": "2024-04-25T14:06:56Z",
      "expires": "2024-04-25T14:16:56Z",
      "state": "healthy"
    },
    {
      "source": "StartProvisionWatcher",
      "time": "2024-04-25T14:06:09Z",
      "expires": "2024-04-25T14:16:09Z",
      "state": "healthy"
    }
  ],
  "retrievedAt": "2024-04-25T14:06:56Z"
}
```

</details>
<br />

To view this information in a visual format, visit your SCIM bridge URL in a web browser. Sign in with your bearer token, then you can view status information and download container log files.

## Connect your identity provider

Use your SCIM bridge URL and bearer token to [connect your identity provider to 1Password SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM bridge

👍 Check for 1Password SCIM Bridge updates on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).

To upgrade your SCIM bridge, `git pull` the latest versions from this repository. Then re-apply the `.yml` file. For example:

```bash
cd scim-examples/
git pull
cd beta/podman/
podman-compose up --build -d
```

After 2-3 minutes, the bridge should come back online with the latest version.

## Appendix: Customize your SCIM bridge

Many SCIM bridge configuration changes can be made by adding or removing environment variables. These can be customized by making changes to [`scim.env`](./scim.env) (that can be commited to your source control) before deploying (or redeploying) your SCIM bridge. For some use cases, it may be desirable to update the configuration "on the fly" from your terminal.

### 🔒 Advanced TLS options

Identity providers strictly require an HTTPS endpoint with a vlid TLS certificate to use for the SCIM bridge URL. 1Password SCIM Bridge includes an optional CertificateManager component that (by default) acquires and manages a TLS certificate using Let's Encrypt, and terminates TLS traffic at the SCIM bridge container using this certificate. This requires port 443 of the Podman host to be publicly accessible to ensure Let's Encrypt can initiate an inbound connection to your SCIM bridge.

Other supported options include:

#### External load balancer or reverse proxy

To terminate TLS traffic at another public endpoint and redirect private traffic to a Podman host in your private network, SCIM bridge can be configured to disable the CertificateManager component and serve plain-text HTTP traffic on port 80 of the Podman host. CertificateManager will be enabled if a value is set for the `OP_TLS_DOMAIN` variable, so any value set in `scim.env` must be removed (or this line must be commented out). The included `podman.http.yaml` file can be used to set up the port mapping when deploying (or redeploying) SCIM bridge:

#### Self-managed TLS certificate

You may supply your own TLS certificate with CertificateManager instead of invoking Let's Encrypt. The value set for `OP_TLS_DOMAIN` must match the common name of the certificate.

Save the public and private certificate key files as `certificate.pem` and `key.pem` (respectively) to the working directory and use the included `podman.custom-tls.yaml` file when deploying SCIM bridge to configure SCIM bridge using this certificate when terminating TLS traffic. So the command you should be running when deploying the SCIM bridge is as follows.

```
./deploy.sh --file podman.custom-tls.yml
```

### Custom Redis Options

- `OP_REDIS_URL`: You can specify a `redis://` or `rediss://` (for TLS) URL here to point towards a different Redis host. You can then remove the sections in `podman.template.yml` that refer to Redis to not deploy that container. Redis is still required for the SCIM bridge to function.

As of 1Password SCIM Bridge `v2.8.5`, additional Redis configuration options are available. `OP_REDIS_URL` must be unset for any of these environment variables to be read. These environment variables may be especially helpful if you need support for URL-unfriendly characters in your Redis credentials. These can be set in `scim.env`.

> **Note**  
> `OP_REDIS_URL` must be unset, otherwise the following environment variables will be ignored.

- `OP_REDIS_HOST`: overrides the default hostname of the redis server (default: `redis`). It can be either another hostname, or an IP address.
- `OP_REDIS_PORT`: overrides the default port of the redis server connection (default: `6379`).
- `OP_REDIS_USERNAME`: sets a username, if any, for the redis connection (default: `(null)`)
- `OP_REDIS_PASSWORD`: Sets a password, if any, for the redis connection (default: `(null)`). Can accommodate URL-unfriendly characters that `OP_REDIS_URL` may not accommodate.
- `OP_REDIS_ENABLE_SSL`: Optionally enforce SSL on redis server connections (default: `false`). (Boolean `0` or `1`)
- `OP_REDIS_INSECURE_SSL`: Set whether to allow insecure SSL on redis server connections when `OP_REDIS_ENABLE_SSL` is set to `true`. This may be useful for testing or self-signed environments (default: `false`) (Boolean `0` or `1`).

### Advanced `scim.env` options

The following options are available for advanced or custom deployments. Unless you have a specific need, these options do not need to be modified.

* `OP_PORT`: When `OP_TLS_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one you choose.
* `OP_PRETTY_LOGS`: You can set this to `1` if you'd like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren't planning on doing custom log ingestion in your environment.
* `OP_DEBUG`: You can set this to `1` to enable debug output in the logs, which is useful for troubleshooting or working with 1Password Support to diagnose an issue.
* `OP_TRACE`: You can set this to `1` to enable trace-level log output, which is useful for debugging Let’s Encrypt integration errors.
* `OP_PING_SERVER`: You can set this to `1` to enable an optional `/ping` endpoint on port `80`, which is useful for health checks. It's disabled if `OP_TLS_DOMAIN` is unset and TLS is not in use.
