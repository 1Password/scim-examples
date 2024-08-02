# Deploy 1Password SCIM Bridge with Docker

*Learn how to deploy 1Password SCIM Bridge using Docker Compose or Docker Swarm.*

## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md).

## Step 1: Choose a deployment option

Using Docker, you have two deployment options: [Docker Compose](https://docs.docker.com/compose/) and [Docker Swarm](https://docs.docker.com/engine/swarm/).

**Docker Swarm** is the recommended option, but Docker Compose can also be used depending on your deployment needs. You can set up a Docker host on your own infrastructure or on a cloud provider of your choice.

The `scimsession` file is passed into the docker container using an environment variable, which is less secure than Docker Swarm secrets, Kubernetes secrets, or AWS Secrets Manager, all of which are supported and recommended for production use.

## Step 2: Install Docker tools

1. On your local machine, install [Docker for Desktop](https://www.docker.com/products/docker-desktop) and start Docker.
2. Install the `docker-compose` and `docker-machine` command-line tools on your local machine. If you're using macOS and Homebrew, make sure you're using the _cask_ app-based version of Docker (`brew cask install docker`), not the default CLI version.

## Step 3: Deploy 1Password SCIM Bridge

To automatically deploy 1Password SCIM Bridge with [Docker Swarm](#docker-swarm) or [Docker Compose](#docker-compose), use our script, [./docker/deploy.sh](deploy.sh).

### Docker Swarm

For this method, you'll need to have joined a Docker Swarm with the target deployment node. Learn how to [create a swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

After you've created a swarm, log in with `docker swarm join`. Then use the provided [`deploy.sh`](/docker/deploy.sh) Bash script to deploy your SCIM bridge. The script will do the following:

1. Ask whether you're using Google Workspace as your identity provider so you can add your configuration files as Docker Secrets within your Swarm cluster.
2. Ask whether you're deploying using Docker Swarm or Docker Compose.
3. Ask for your SCIM bridge domain name so you can automatically get a TLS certificate from Let's Encrypt. This is the domain you selected in [PREPARATION.md](/PREPARATION.md).
4. Ask for your `scimsession` file location to add your `scimsession` file as a Docker Secret within your Swarm cluster.
5. Deploy a container using `1password/scim`, as well as a `redis` container. The `redis` container is necessary to store Let's Encrypt certificates, as well as act as a cache for your identity provider information.

The logs from the SCIM bridge and Redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point, you should set a DNS record routing the domain name to the IP address of the `op-scim` container.

> [!IMPORTANT]
> The DNS record name is used for your **SCIM bridge URL**. For example, if the record name is `op-scim-bridge.example.com`, then your SCIM bridge URL is `https://op-scim-bridge.example.com`.

### Docker Compose

To deploy with Docker Compose, you'll need Docker Desktop set up either locally or remotely. Learn how to [set up Docker Desktop](https://docs.docker.com/desktop/). Then follow these steps:

1. Make sure your environment is set up by running the command `eval %{docker-machine env $machine_name}` using the machine name you've chosen.
2. Run the [`deploy.sh`](/docker/deploy.sh) script.
3. Choose Compose as the deployment method when prompted. Any references for Docker Secrets will be added to the Docker Compose deployment as environment variables.

<hr>

## Advanced Manual deployment

<details>
<summary>How to manually deploy 1Password SCIM Bridge</summary>

You can also manually deploy the SCIM bridge with [Docker Swarm](#docker-swarm-manual-deployment) or [Docker Compose](#docker-compose-manual-deployment).

### Clone `scim-examples`

You'll need to clone this repository using `git` into a directory of your choice:

```bash
git clone https://github.com/1Password/scim-examples.git
```

You can then browse to the Docker directory:

```bash
cd scim-examples/docker/
```

### Docker Swarm manual deployment

To use Docker Swarm, run `docker swarm init` or `docker swarm join` on the target node and complete that portion of the setup. Refer to [Docker's documentation for more details](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

Unlike Docker Compose, you won't need to set the `OP_SESSION` variable in `scim.env`. Instead, you'll use Docker Secrets to store the `scimsession` file. You'll still need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name. This is also needs to be set for self-managed TLS Docker Swarm deployment.

> If you use Google Workspace as your identity provider, you'll need to set up some additional secrets:
> 
> First, edit the [`workspace-settings.json`](/docker/swarm/workspace-settings.json) file in this folder and enter the appropriate details. Then create the necessary secrets for Google Workspace:
>
> ```bash
> # this is the path of the JSON file you edited in the paragraph above
> docker secret create workspace-settings ./workspace-settings.json
> # replace ./workspace-credentials.json with the path to the file Google generated for your Google Service Account
> docker secret create workspace-credentials ./workspace-credentials.json 
> ```

<br>

After that's set up, you can do the following (using the alternate command for the stack deployment if using Google Workspace as your identity provider):

```bash
# enter the swarm directory
cd scim-examples/docker/swarm/
# sets up a Docker Secret on your Swarm
cat /path/to/scimsession | docker secret create scimsession -
# deploy your Stack
docker stack deploy -c docker-compose.yml op-scim
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```

Alternate Google Workspace stack deployment command:

``` bash
# deploy your Stack with Google Workspace settings
docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim
```

Learn more about [connecting Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/).

### Self managed TLS for Docker Swarm

Provide your own key and cert files to the deployment as secrets, which disables Let's Encrypt functionality. In order to utilize self managed TLS key and certificate files, you need to define these as secrets using the following commands and And finally, use `docker stack` to deploy:

```bash
cat /path/to/private.key | docker secret create op-tls-key -
cat /path/to/cert.crt | docker secret create op-tls-crt -
```

Use `docker stack` to deploy:

``` bash
# deploy your Stack with self-managed TLS using Docker Secrets
docker stack deploy -c docker-compose.yml -c docker.tls.yml op-scim
```

``` bash
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```

### Docker Compose manual deployment

When using Docker Compose, you can create the environment variable `OP_SESSION` manually by doing the following:

```bash
# only needed for Docker Compose - use Docker Secrets when using Swarm
# enter the compose directory (if you aren't already in it)
cd scim-examples/docker/compose/
SESSION=$(cat /path/to/scimsession | base64 | tr -d "\n")
sed -i '' -e "s/OP_SESSION=$/OP_SESSION=$SESSION/" ./scim.env
```

You'll also need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name.

Ensure that `OP_TLS_DOMAIN` is set to the domain name you've set up before you continue.

#### If you use Google Workspace as your identity provider

It is not recommended to use Docker Compose for your SCIM bridge deployment if you are integrating with Google Workspace. Consider [using Docker Swarm](#docker-swarm-manual-deployment) instead.

</details>

<hr>

## Step 4: Test the SCIM bridge

Use your SCIM bridge URL to test the connection and view status information. For example:

```sh
curl --silent --show-error --request GET --header "Accept: application/json" \
  --header "Authorization: Bearer mF_9.B5f-4.1JqM" \
  https://op-scim-bridge.example.com/health
```

Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://op-scim-bridge.example.com` with your SCIM bridge URL.

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

## Step 5: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM bridge

Check for 1Password SCIM Bridge updates on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/).

To upgrade your SCIM bridge, `git pull` the latest versions from this repository. Then re-apply the `.yml` file. For example:

### Docker Swarm

```bash
cd scim-examples/
git pull
cd docker/swarm/
# For Docker Swarm updates:
# add second yaml if using Google Workspace `docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim`
docker stack deploy -c docker-compose.yml op-scim
```

### Docker Compose

```bash
cd scim-examples/
git pull
cd docker/compose/
# for Docker Compose updates:
docker-compose -f docker-compose.yml up --build -d
```

After 2-3 minutes, the bridge should come back online with the latest version.

## Appendix: Advanced `scim.env` options

The following options are available for advanced or custom deployments. Unless you have a specific need, these options do not need to be modified.

* `OP_TLS_CERT_FILE` and `OP_TLS_KEY_FILE`: These two variables can be set to the paths of a key file and certificate file secrets, which will disable Let's Encrypt functionality, causing the SCIM bridge to use your own manually-defined certificate when `OP_TLS_DOMAIN` is also defined. This is only supported with Docker Swarm, not Docker Compose. Note the additional steps above in the [manual self managed TLS section](#Self-managed-TLS-for-Docker-Swarm) for enabling this feature.
* `OP_PORT`: When `OP_TLS_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one you choose.
* `OP_REDIS_URL`: You can specify a `redis://` or `rediss://` (for TLS) URL here to point towards a different Redis host. You can then remove the sections in `docker-compose.yml` that refer to Redis to not deploy that container. Redis is still required for the SCIM bridge to function.  
* `OP_PRETTY_LOGS`: You can set this to `1` if you'd like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren't planning on doing custom log ingestion in your environment.
* `OP_DEBUG`: You can set this to `1` to enable debug output in the logs, which is useful for troubleshooting or working with 1Password Support to diagnose an issue.
* `OP_TRACE`: You can set this to `1` to enable trace-level log output, which is useful for debugging Let's Encrypt integration errors.
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

## Appendix: Generate `scim.env` on Windows

On Windows, refer to [./docker/compose/generate-env.bat](generate-env.bat) to learn how to generate the `base64` string for `OP_SESSION`.
