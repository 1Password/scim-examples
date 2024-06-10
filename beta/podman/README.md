# [Beta] Deploy 1Password SCIM Bridge using Podman

This example describes how to deploy 1Password SCIM Bridge using [Podman](https://podman.io/) and [Podman-compose](https://github.com/containers/podman-compose). The deployment includes two containers, one each for the SCIM bridge container and the required Redis cache. This deployment is recommended for users who can only use Red Hat Enterprise Linux (RHEL) VM for their on-prem deployment since Docker will have issues running on these VMs.
Podman-compose is a community developed package that enables Podman to achieve the same functionality as Docker Compose. It allows users to specify all the necessary details inside a single file, usually called `docker-compose.yml`.

> **Before you move on**
>
> If you are using Google Workspace or need to send more than 1000 provisioning requests at a time, please reach out to 1Password support team as these are not supported with Podman deployment yet.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`docker-compose.yaml`](./docker-compose.yaml): a [Compose Specification](https://docs.docker.com/compose/compose-file/) format [Compose file](https://docs.docker.com/compose/compose-file/03-compose-file/) for 1Password SCIM Bridge.
- [`redis.conf`](./redis.conf): a [Redis configuration file](https://redis.io/docs/management/config/) to load the Redis cache with the base configuration required for SCIM bridge
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

2. Save the `scimsession` credentials file from [the Automated User Provisioning setup](https://start.1password.com/integrations/directory/) to this working directory.

   > **Note**
   >
   > 💻 If you saved your `scimsession` file as an item in your 1Password account, you can
   > [use 1Password CLI](https://developer.1password.com/docs/cli/reference/commands/read) to save the file to this
   > directory. For example:
   >
   > ```sh
   > op read "op://Private/scimsession file/scimsession" --out-file ./scimsession
   > ```

3. Open `scim.env` in your favourite text editor. Set the value of `OP_TLS_DOMAIN` to the fully qualififed domain name of the public DNS record for your SCIM bridge created in [Get started](#get-started). For example:

   ```dotenv
   # ...
   OP_TLS_DOMAIN=scim.example.com

   # ...
   ```

   Save the file.

4. Run the compose file by using the command below

   _Example command:_

   ```sh
   podman-compose up --build -d
   ```


## Test your SCIM bridge

Run this command to view logs from the service for the SCIM bridge container:

```sh
docker service logs op-scim-bridge_scim --raw
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


### Docker Compose

```bash
cd scim-examples/
git pull
cd docker/compose/
podman-compose up --build -d
```

After 2-3 minutes, the bridge should come back online with the latest version.

## Appendix: Advanced `scim.env` options

The following options are available for advanced or custom deployments. Unless you have a specific need, these options do not need to be modified.

* `OP_PORT`: When `OP_TLS_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one you choose.
* `OP_REDIS_URL`: You can specify a `redis://` or `rediss://` (for TLS) URL here to point towards a different Redis host. You can then remove the sections in `docker-compose.yml` that refer to Redis to not deploy that container. Redis is still required for the SCIM bridge to function.  
* `OP_PRETTY_LOGS`: You can set this to `1` if you'd like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren't planning on doing custom log ingestion in your environment.
* `OP_DEBUG`: You can set this to `1` to enable debug output in the logs, which is useful for troubleshooting or working with 1Password Support to diagnose an issue.
* `OP_TRACE`: You can set this to `1` to enable trace-level log output, which is useful for debugging Let’s Encrypt integration errors.
* `OP_PING_SERVER`: You can set this to `1` to enable an optional `/ping` endpoint on port `80`, which is useful for health checks. It's disabled if `OP_TLS_DOMAIN` is unset and TLS is not in use.

As of 1Password SCIM Bridge `v2.8.5`, additional Redis configuration options are available. `OP_REDIS_URL` must be unset for any of these environment variables to be read. These environment variables may be especially helpful if you need support for URL-unfriendly characters in your Redis credentials. 

> **Note**  
> `OP_REDIS_URL` must be unset, otherwise the following environment variables will be ignored.

* `OP_REDIS_HOST`:  overrides the default hostname of the redis server (default: `redis`). It can be either another hostname, or an IP address.
* `OP_REDIS_PORT`: overrides the default port of the redis server connection (default: `6379`).
* `OP_REDIS_USERNAME`: sets a username, if any, for the redis connection (default: `(null)`)
* `OP_REDIS_PASSWORD`: Sets a password, if any, for the redis connection (default: `(null)`). Can accommodate URL-unfriendly characters that `OP_REDIS_URL` may not accommodate. 
* `OP_REDIS_ENABLE_SSL`: Optionally enforce SSL on redis server connections (default: `false`).   (Boolean `0` or `1`)
* `OP_REDIS_INSECURE_SSL`: Set whether to allow insecure SSL on redis server connections when `OP_REDIS_ENABLE_SSL` is set to `true`. This may be useful for testing or self-signed environments (default: `false`) (Boolean `0` or `1`).
