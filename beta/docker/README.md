# [Beta] Deploy 1Password SCIM Bridge using Docker Swarm

This example describes how to deploy 1Password SCIM Bridge as a [stack](https://docs.docker.com/engine/swarm/stack-deploy/) using [Docker Swarm](https://docs.docker.com/engine/swarm/key-concepts/#what-is-a-swarm). The stack includes two [services](https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/) (one each for the SCIM bridge container and the required Redis cache), a [Docker secret](https://docs.docker.com/engine/swarm/secrets/) for the `scimsession` credentials, a [Docker config](https://docs.docker.com/engine/swarm/configs/) for configuring Redis, and optional secrets and configuration required only for customers integrating with Google Workspace.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`compose.template.yaml`](./compose.template.yaml): a [Compose Specification](https://docs.docker.com/compose/compose-file/) format [Compose file](https://docs.docker.com/compose/compose-file/03-compose-file/) for 1Password SCIM Bridge.
- [`compose.gw.yaml`](./compose.gw.yaml): an [override configuration](https://docs.docker.com/compose/multiple-compose-files/merge/) to merge the configuration necessary for customers integrating with Google Workspace.
- [`compose.http.yaml`](./compose.http.yaml): optional configuration for exposing an HTTP port on the Docker host for forwarding plain-text traffic within a private network from a public TLS termination endpoint
- [`compose.tls.yaml`](./compose.http.yaml): optional configuration for enabling a self-managed TLS certificate
- [`redis.conf`](./redis.conf): a [Redis configuration file](https://redis.io/docs/management/config/) to load the Redis cache with the base configuration required for SCIM bridge
- [`scim.env`](./scim.env): an environment file used to customize the SCIM bridge configuration

## Overview

The open source Docker Engine tooling can be used to deploy 1Password SCIM Bridge on any supported Linux distribution. A single-node swarm is sufficient for most deployments. This example assumes that the Linux server is exposed directly to the public internet with Docker acting as a reverse proxy to the SCIM bridge container.

## Prerequisites

- AMD64/ARM64 VM or bare metal server with a Docker-supported Linux distribution (e.g. Ubuntu, Debian, Fedora, etc.)
- Docker Engine (see [Docker Engine installation overview](https://docs.docker.com/engine/install/#server)) installed on the Linux server
- a public DNS A record pointing to the Linux server
- SSH access to the Linux server
- [Docker Desktop](https://docs.docker.com/engine/install/#desktop) or Docker Engine installed on a machine with access to the Linux server and credentials from your 1Password account

## Get started

> **Note**
>
> 📚 Before proceeding, review the [Preparation Guide](/PREPARATION.md) at the root of this repository.

Create a public DNS A record that points to the public IP address of the Linux server for your SCIM bridge. For example, `scim.example.com`.

### 🛠️ Prepare the Linux server

On the Linux machine that you will be using as the Docker host for your SCIM bridge:

1. If you haven't already done so, [install Docker Engine](https://docs.docker.com/engine/install/#server) on the Linux server. Follow the Server instructions; Docker Desktop is not needed for the Linux server.
2. Follow the [post-install steps](https://docs.docker.com/engine/install/linux-postinstall/) as noted in the documentation to enable running Docker as a non-root user and ensure that Docker Engine starts when the Linux server boots.

### 👨‍💻 Prepare your desktop

All following steps should be run on the same computer where you are already using 1Password, or another machine that can access the Linux server using SSH and has access to the `scimsession` file from the integration setup:

1. If you haven't already done so, install Docker. You can use [Docker Desktop](https://docs.docker.com/engine/install/#desktop), [install Docker Engine from binaries](https://docs.docker.com/engine/install/binaries/), or install Docker using your favourite package manager.

2. Open your preferred terminal. Clone this repository and switch to this directory:

   ```sh
   git clone https://github.com/1Password/scim-examples.git
   cd ./scim-examples/beta/docker
   ```

3. Save the `scimsession` credentials file from [the Automated User Provisioning setup](https://start.1password.com/integrations/directory/) to this working directory.

   > **Note**
   >
   > 💻 If you saved your `scimsession` file as an item in your 1Password account, you can
   > [use 1Password CLI](https://developer.1password.com/docs/cli/reference/commands/read) to save the file to this
   > directory. For example:
   >
   > ```sh
   > op read "op://Private/scimsession file/scimsession" --out-file ./scimsession
   > ```

4. Open `scim.env` in your favourite text editor. Set the value of `OP_TLS_DOMAIN` to the fully qualififed domain name of the public DNS record for your SCIM bridge created in [Get started](#get-started). For example:

   ```dotenv
   # ...
   OP_TLS_DOMAIN=scim.example.com

   # ...
   ```

   Save the file.

5. Create a Docker context to use for connecting to the Linux server:

   _Example command:_

   ```sh
   docker context create op-scim-bridge \
       --description "1Password SCIM Bridge Docker host" \
       --docker host=ssh://user@scim.example.com
   ```

   Copy the example command to a text editor. Replace `user` with the appropriate username for your Linux server and `scim.example.com` with the host name or IP address used for SSH access to the Linux server before running the command in your terminal.

   > **Note**
   >
   > 🔑 You can store your SSH keys in 1Password and authenticate this and other SSH workflows without writing a
   > private key to disk using the [1Password SSH agent](https://developer.1password.com/docs/ssh/get-started).

6. Switch to the Docker context you just created to connect to the Docker host:

   ```sh
   docker context use op-scim-bridge
   ```

### 🪄 Create a swarm

Run this command to create the swarm:

```sh
docker swarm init # --advertise-addr 192.0.2.1
```

> **Note**
>
> Additional nodes may be optionally added to a swarm for fault tolerance. This command adds the Linux server as the
> first (and only) node in the swarm, but Docker _requires_ a unique IP address to advertise to other nodes (even if
> no other nodes will be added). See [How nodes work](https://docs.docker.com/engine/swarm/how-swarm-mode-works/nodes/)
> in the Docker documentation for more details.
>
> If multiple IP addresses are detected, Docker returns an error; uncomment the `--advertise-addr` parameter (delete
> `#`), replace the example IP (`192.0.2.1`) with the appropriate IP address, and run the command again.

### Configure 1Password SCIM bridge to connect to Google Workspace

Additional configuration and credentials are required to integrate to integrate your 1Password account with Google Workspace.

> **Warning**
>
> ⏩ This section is **only** for customers who are integrating 1Password with Google Workspace for automated user
> provisioning. If you are _not_ integrating with Workspace, skip the steps in this section and
> [deploy your SCIM bridge](#%EF%B8%8F-deploy-1password-scim-bridge)

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

   Save the file.

## Deploy 1Password SCIM Bridge

Use the Compose template to output a canonical configuration for use with Docker Swarm and create the stack from this configuration inline. Your SCIM bridge should automatically acquire and manage a TLS certificate from Let's Encrypt on your behalf:

```sh
docker stack config \
    --compose-file ./compose.template.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

### Connect your SCIM bridge to Google Workspace

If you are integrating with Google Workspace, use the `compose.gw.yaml` override Compose file.

> **Warning**
>
> ⏩ This section is **only** for customers who are integrating 1Password with Google Workspace for automated user
> provisioning. If you are _not_ integrating with Workspace, skip this section and [test your SCIM bridge](#-test-your-scim-bridge).

Merge the configuration to create and use the additional Docker secrets needed for Workspace into the canonical configuration:

```sh
docker stack config \
    --compose-file ./compose.template.yaml \
    --compose-file ./compose.gw.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

## Test your SCIM bridge

Run this command to retrieve logs from the service for the SCIM bridge container:

```sh
docker service logs op-scim-bridge_scim --raw
```

Your SCIM bridge URL is based on the fully qualified domain name of the DNS record created in [Get started](#get-started), for example `https://scim.example.com/`. You can access your SCIM bridge in a web browser at this URL by signing in using your bearer token.

You can also test your SCIM bridge by sending an authenticated SCIM API request.

_Example command:_

```sh
curl --header "Authorization: Bearer mF_9.B5f-4.1JqM" https://scim.example.com/Users
```

Copy the example command to a text editor. Replace `mF_9.B5f-4.1JqM` with your bearer token and `scim.example.com` with the fully qualified domain name of the DNS record created in [Get started](#get-started) before running the command in your terminal.

> **Note**
>
> 💻 If you saved your bearer token as an item in your 1Password account, you can [use 1Password CLI to securely pass the
> bearer token](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets)
> instead of writing it out in the console. For example: `--header "Authorization: Bearer $(op read
"op://Private/bearer token/credential")"`

<details>
<summary>Example JSON response</summary>

> ```json
> {
>   "Resources": [
>     {
>       "active": true,
>       "displayName": "Eggs Ample",
>       "emails": [
>         {
>           "primary": true,
>           "type": "",
>           "value": "eggs.ample@example.com"
>         }
>       ],
>       "externalId": "",
>       "groups": [
>         {
>           "value": "f7eqriu7ht27mq5zmm63gf2dhq",
>           "ref": "https://scim.example.com/Groups/f7eqriu7ht27mq5zmm63gf2dhq"
>         }
>       ],
>       "id": "FECPUMYBHZB2PB6K4WKM4Q2HAU",
>       "meta": {
>         "created": "",
>         "lastModified": "",
>         "location": "",
>         "resourceType": "User",
>         "version": ""
>       },
>       "name": {
>         "familyName": "Ample",
>         "formatted": "Eggs Ample",
>         "givenName": "Eggs",
>         "honorificPrefix": "",
>         "honorificSuffix": "",
>         "middleName": ""
>       },
>       "schemas": [
>         "urn:ietf:params:scim:schemas:core:2.0:User"
>       ],
>       "userName": "eggs.ample@example.com"
>     },
>     ...
>   ]
> }
> ```

</details>

## Connect your identity provider

Use your SCIM bridge URL and bearer token to [connect your identity provider to 1Password SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).


## Update 1Password SCIM Bridge

Swarm mode in Docker Engine uses a declarative service model. Services will automatically restart tasks when updating their configuration.

Use the Docker context from [Prepare your desktop](#-prepare-your-desktop) to connect to your Docker host and manage your stack.

Update the `op-scim-bridge_scim` service with the new image tag from the [`1password/scim` repository on Docker Hub](https://hub.docker.com/r/1password/scim/tags) to update your SCIM bridge to a new version:

```sh
docker service update op-scim-bridge_scim \
    --image 1password/scim:v2.9.4
```

> **Note**
>
> You can find details about the changes in each release of 1Password SCIM Bridge on our
> [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website. The most recent version should be
> pinned in the [`compose.template.yaml`](./compose.template.yaml) file (and in the command above in this file) in the main branch
> of this GitHub repository.

Your SCIM bridge should automatically reboot using the specified version, typically in a few moments.

## Rotate credentials

Docker secrets are immutable and cannot be removed while in use by a Swarm service. To use new secret values in your stack, you must remove the existing secret from the service configuration, replace the Docker secret (or add a new one), and update the service configuration to mount the new secret value.

For example, if you regenerate credentials for the automated user provisioning integration:

1. Scale down the `op-scim-bridge_scim` service to shut down the running SCIM bridge task.

   ```sh
   docker service scale op-scim-bridge_scim=0
   ```

2. Update the service definition to unnmount the the `scimsession` Docker secret:

   ```sh
   docker service update op-scim-bridge_scim \
       --secret-rm scimsession
   ```

3. Remove the secret from the swarm:

   ```sh
   docker secret rm scimsession
   ```

4. Copy the regenerated `scimsession` file from your 1Password account to your working directory. Create a new `scimsession` Docker secret using the new file:

   ```sh
   docker secret create scimsession ./scimsession
   ```

   > **Note**
   >
   > 💻 If you saved your `scimsession` file as an item in your 1Password account, you can
   > [use 1Password CLI](https://developer.1password.com/docs/cli/reference/commands/read) to create the new Docker
   > secret instead (without saving it to disk on your machine). For example:
   >
   > ```sh
   > op read "op://Private/scimsession file/scimsession" | docker secret create scimsession -
   > ```

5. Update the service to mount the new `scimsession` secret:

   ```sh
   docker service update op-scim-bridge_scim \
       --secret-add source=scimsession,target=scimsession,uid="999",gid="999",mode=0440
   ```

6. Scale the `op-scim-bridge_scim` service back up to reboot your SCIM bridge:

   ```sh
   docker service scale op-scim-bridge_scim=1
   ```

[Test your SCIM bridge](#-test-your-scim-bridge) using the new bearer token associated with the regenerated `scimsession` file. Update your identity provider configuration with the new bearer token.

A similar process can be used to update the values for any other Docker secrets used in your configuration.

## Appendix: Resource recommendations

The 1Password SCIM Bridge container should be vertically scaled when provisioning a large number of users or groups. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 125m  | 512M   |
| High      | 1,000–5,000     | 500m  | 1024M  |
| Very high | >5,000          | 1000m | 1024M  |

If provisioning more than 1,000 users, the resources assigned to the SCIM bridge container should be updated as recommended in the above table. The resources specified for the Redis container do not need to be adjusted.

Resource configuration can be updated in place:

### Default resources

Resources for the SCIM bridge container are defined in [`compose.template.yaml`](https://github.com/1Password/scim-examples/blob/main/beta/docker/compose.template.yaml):

```yaml
services:
  ...
  scim:
    ...
    deploy:
      resources:
        reservations:
          cpus: "0.125"
          memory: 512M
        limits:
          memory: 512M
          ...
```

After making any changes to the Deployment resource in your cluster, you can apply the unmodified manifest to revert to the default specifications defined above:

```sh
docker stack deploy -c compose.template.yaml op-scim
```

### High volume

For provisioning up to 5,000 users:

```sh
docker service update op-scim-bridge --reserve-cpu 500m --reserve-memory 1024M --limit-memory 1024M
```

### Very high volume

For provisioning more than 5,000 users:

```sh
docker service update op-scim-bridge --reserve-cpu 1000m --reserve-memory 1024M --limit-memory 1024M
```

Please reach out to our [support team](https://support.1password.com/contact/) if you need help with the configuration or to tweak the values for your deployment.

## Appendix: Customize your SCIM bridge

Many SCIM bridge configuration changes can be made by adding or removing environment variables. These can be customized by making changes to [`scim.env`](./scim.env) (that can be commited to your source control) before deploying (or redeploying) your SCIM bridge using the `docker stack deploy` command. For some use cases, it may be desirable to update the configuration "on the fly" from your terminal.

For example, to reboot your SCIM bridge with debug logging enabled:

```sh
docker service update op-scim-bridge_scim \
    --env-add OP_DEBUG=1
```

To turn off debug logging and inject some colour into the logs in your console:

```sh
docker service update op-scim-bridge_scim \
    --env-rm OP_DEBUG \
    --env-add OP_PRETTY_LOGS=1
```

_Pretty logs pair nicely with the `--raw` parameter of the `docker service logs` command). 🤩_

### 🔒 Advanced TLS options

Identity providers strictly require an HTTPS endpoint with a vlid TLS certificate to use for the SCIM bridge URL. SCIM Bridge includes an optional CertificateManager component that (by default) acquires and manages a TLS certificate using Let's Encrypt, and terminates TLS traffic at the SCIM bridge container using this certificate. This requires port 443 of the Docker host to be publicly accessible to ensure Let's Encrypt can initiate an inbound connection to your SCIM bridge.

Other supported options include:

#### External load balancer or reverse proxy

To terminate TLS traffic at another public endpoint and redirect private traffic to a Docker host in your private network, SCIM bridge can be configured to disable the CertificateManager component and serve plain-text HTTP traffic on port 80 of the Docker host. CertificateManager will be enabled if a value is set for the `OP_TLS_DOMAIN` variable, so any value set in `scim.env` must be removed (or this line must be commented out). The included `compose.http.yaml` file can be used to set up the port mapping when deploying (or redeploying) SCIM bridge:

```sh
docker stack config \
    --compose-file ./compose.template.yaml \
    --compose-file ./compose.http.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

#### Self-managed TLS certificate

You may supply your own TLS certificate with CertificateManager instead of invoking Let's Encrypt. The value set for `OP_TLS_DOMAIN` must match the common name of the certificate.

Save the public and private certificate key files as `certificate.pem` and `key.pem` (respectively) to the working directory and use the included `compose.tls.yaml` file when deploying SCIM bridge to create Docker secrets and configure SCIM bridge use this certificate when terminating TLS traffic:

```sh
docker stack config \
    --compose-file ./compose.template.yaml \
    --compose-file ./compose.tls.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

### Custom Redis Options

- `OP_REDIS_URL`: You can specify a `redis://` or `rediss://` (for TLS) URL here to point towards a different Redis host. You can then remove the sections in `docker-compose.yml` that refer to Redis to not deploy that container. Redis is still required for the SCIM bridge to function.

As of SCIM Bridge `v2.8.5`, additional Redis configuration options are available. `OP_REDIS_URL` must be unset for any of these environment variables to be read. These environment variables may be especially helpful if you need support for URL-unfriendly characters in your Redis credentials. These can be set in [`compose.template.yaml`](./compose.template.yaml) at `services.scim.environment`.

> **Note**  
> `OP_REDIS_URL` must be unset, otherwise the following environment variables will be ignored.

- `OP_REDIS_HOST`: overrides the default hostname of the redis server (default: `redis`). It can be either another hostname, or an IP address.
- `OP_REDIS_PORT`: overrides the default port of the redis server connection (default: `6379`).
- `OP_REDIS_USERNAME`: sets a username, if any, for the redis connection (default: `(null)`)
- `OP_REDIS_PASSWORD`: Sets a password, if any, for the redis connection (default: `(null)`). Can accommodate URL-unfriendly characters that `OP_REDIS_URL` may not accommodate.
- `OP_REDIS_ENABLE_SSL`: Optionally enforce SSL on redis server connections (default: `false`). (Boolean `0` or `1`)
- `OP_REDIS_INSECURE_SSL`: Set whether to allow insecure SSL on redis server connections when `OP_REDIS_ENABLE_SSL` is set to `true`. This may be useful for testing or self-signed environments (default: `false`) (Boolean `0` or `1`).
