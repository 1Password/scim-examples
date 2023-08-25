# [Beta] Deploy 1Password SCIM Bridge using Docker Swarm

This example describes how to deploy 1Password SCIM Bridge as a [stack](https://docs.docker.com/engine/swarm/stack-deploy/) using [Docker Swarm](https://docs.docker.com/engine/swarm/key-concepts/#what-is-a-swarm). The stack includes two [services](https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/) (one each for the SCIM bridge container and the required Redis cache), a [Docker secret](https://docs.docker.com/engine/swarm/secrets/) for the `scimsession` credentials, a [Docker config](https://docs.docker.com/engine/swarm/configs/) for configuring Redis, and optional secrets and configuration required only for customers integrating with Google Workspace.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`compose.template.yaml`](./compose.template.yaml): a [Compose Specification](https://docs.docker.com/compose/compose-file/) format [Compose file](https://docs.docker.com/compose/compose-file/03-compose-file/) for 1Password SCIM Bridge.
- [`compose.gw.yaml`](./compose.gw.yaml): an [override configuration](https://docs.docker.com/compose/multiple-compose-files/merge/) to merge the configuration necessary for customers integrating with Google Workspace.
- [`redis.conf`](./redis.conf): a [Redis configuration file](https://redis.io/docs/management/config/) to load the Redis cache with the base configuration required for SCIM bridge
- [`scim.env`](./scim.env): an environment file that can be used to customize the SCIM bridge configuration.

## Overview

The open source Docker Engine tooling can be used to deploy 1Password SCIM Bridge on any supported Linux distribution. A single-node swarm is sufficient for most deployments. This example assumes that the Linux server is exposed directly to the public internet with Docker acting as a reverse proxy to the SCIM bridge container. Other configurations are possible, but not documented in this deployment example.

## Prerequisites

- AMD64 VM or bare metal server with a Docker-supported Linux distribution (e.g. Ubuntu, Debian, Fedora, etc.)
- Docker Engine (see [Docker Engine installation overview](https://docs.docker.com/engine/install/#server)) installed on the Linux server
- a public DNS A record pointing to the Linux server
- SSH access to the Linux server
- [Docker Desktop](https://docs.docker.com/desktop/install/) or Docker Engine installed on a machine with access to the Linux server and credentials from your 1Password account

## Get started

Before proceeding, review the [Preparation Guide](/PREPARATION.md) at the root of this repository. Create a public DNS A record that points to the public IP address of the Linux server for your SCIM bridge. For example, `scim.example.com`.

### 🛠️ Prepare the Linux server

On the Linux machine that you will be using as the Docker host for your SCIM bridge:

1. If you haven't already done so, [install Docker Engine](https://docs.docker.com/engine/install/#server) on the Linux server. Follow the Server instructions; Docker Desktop is not needed for the Linux server.
2. Follow the [post-install steps](https://docs.docker.com/engine/install/linux-postinstall/) as noted in the documentation to enable running Docker as a non-root user and ensure that Docker Engine starts when the Linux server boots.

### 👨‍💻 Prepare your desktop and initialize the Swarm

All following steps should be run on the same computer where you are already using 1Password, or another machine that can access the Linux server using SSH and has access to the `scimsession` file from the integration setup:

1. If you haven't already done so, install Docker. You can use [Docker Desktop](https://docs.docker.com/desktop/install/), [install Docker Engine from binaries](https://docs.docker.com/engine/install/binaries/), or install Docker using your favourite package manager.

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
   > op read --out-file ./scimsession "op://Private/scimsession file/scimsession"
   > ```

4. Open `scim.env` in your favourite text editor. Set the value of `OP_TLS_DOMAIN` to the fully qualififed domain name of the public DNS record for your SCIM bridge created in [Get started](#get-started). For example:

   ```dotenv
   # ...
   OP_TLS_DOMAIN=scim.example.com
   
   # ...
   ```

   Save the file.

5. Create a Docker context to use for connecting to the Linux server:

   *Example command:*

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

7. Initialize the Swarm. Run this command:

   ```sh
   docker swarm init # --advertise-addr 192.0.2.1
   ```

   > **Note**
   >
   > If Docker returns an error about multiple network interfaces, uncomment the `--advertise-addr` parameter (delete
   > `#`) and replace the example IP (`192.0.2.1`) with the IP address of a network interface on which the server can
   > be reached by other swarm members (even if you are currently only using a single node swarm). See the
   > [`docker swarm init`](https://docs.docker.com/engine/reference/commandline/swarm_init/#--advertise-addr) command
   > in the Docker CLI reference documentation for more details.

### Configure 1Password SCIM bridge to connect to Google Workspace

If integrating 1Password with Google Workspace, additional configuration is required. See [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) for instructions to create the service account, key, and API client.

> **Warning**
>
> If you are *not* integrating with Workspace, skip the steps in this section and [deploy your SCIM bridge](#deploy-1password-scim-bridge).

1. Save the Google Workspace service account key to this working directory (or rename after saving) as `workspace-credentials.json`.
2. Copy the [Google Workspace settings template file](/beta/workspace-settings.json) in this repository to the working directory:

    ```sh
    cp ../workspace-settings.json ./workspace-settings.json
    ```

    Edit the file. Replace the values for each key:

    - `actor`: the email address for the administrator that the service account is acting on behalf of
    - `bridgeAddress`: the URL for your SCIM bridge based on the fully qualified domain name of the DNS record created in [Get started](#get-started)

    ```json
    {
        "actor":"admin@example.com",
        "bridgeAddress":"https://scim.example.com"
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

If you are integrating with Google Workspace, use the `compose.gw.yaml` file to merge the Workspace configuration and create the additional Docker secrets needed for Workspace into the canonical configuration inline, and deploy the stack:
> **Warning**
>
> If you are *not* integrating with Workspace, skip this section and [test your SCIM bridge](#test-your-scim-bridge).

```sh
docker stack config \
    --compose-file ./compose.template.yaml \
    --compose-file ./compose.gw.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

## Test your SCIM bridge

Run this command to retrieve logs from the service for the SCIM bridge container:

```sh
docker service logs op-scim-bridge_scim
```

Your SCIM bridge URL is based on the fully qualified domain name of the DNS record created in [Get started](#get-started), for example `https://scim.example.com/`. You can access your SCIM bridge in a web browser at this URL by signing in using your bearer token.

You can also test your SCIM bridge by sending an authenticated SCIM API request.

*Example command:*

```sh
curl --header "Authorization: Bearer mF_9.B5f-4.1JqM" https://scim.example.com/Users
```

Copy the example command to a text editor. Replace `mF_9.B5f-4.1JqM` with your bearer token and `scim.example.com` with the fully qualified domain name of the DNS record created in [Get started](#get-started) before running the command in your terminal.
> **Note**
>
> 💻 If you saved your bearer token as an item in your 1Password account, you can [use 1Password CLI to securely pass the
> bearer token](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets)
> instead of writing it out in the console. For example: `--header "Authorization: Bearer $(op read
> "op://Private/bearer token/credential")"`

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

## Appendix

### Update 1Password SCIM Bridge

Update your SCIM bridge to the latest version by updating its service definition:

```sh
docker service update op-scim-bridge_scim --image 1password/scim:v2.8.3
```
