# Deploy 1Password SCIM Bridge in a single-node Docker Swarm

This example describes how to deploy 1Password SCIM Bridge as a stack to a single-node [Docker swarm](https://docs.docker.com/engine/swarm/key-concepts/#what-is-a-swarm). The stack includes two services (one each for the SCIM bridge container and the container for the required Redis cache), a Docker secret for the `scimsession` credentials, a Docker config for Redis, and optional secrets for customers conecting to Google Workspace.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`compose.template.yaml`](./compose.template.yaml): a [Compose specification](https://docs.docker.com/compose/compose-file/) format  [Compose file](https://docs.docker.com/compose/compose-file/03-compose-file/) for 1Password SCIM Bridge.
- [`compose.gw.yaml`](./compose.gw.yaml): an [override configuration](https://docs.docker.com/compose/multiple-compose-files/merge/) to merge the configuration necessary for customers integrating with Google Workspace.
- [`redis.conf`](./redis.conf): a Redis confguration file for loading the Redis cache with the base configuration required for SCIM bridge
- [`scim.env`](./scim.env): an environment file for configuring SCIM bridge

## Overview

The open source Docker Engine tooling can be used to deploy 1Password SCIM Bridge on any supported Linux distribution. A single-node swarm is sufficient. This example assumes that the Linux server is exposed directly to the public internet with Docker acting as a reverse proxy to the SCIM bridge container. Other configurations are possible, but not documented in this deployment example.

## Prerequisites

- Linux VM or bare metal server supporting Docker
- Docker Engine (v20.10.3+) (see [Docker Engine installation overview](https://docs.docker.com/engine/install/#server))
- public DNS record pointing to the Linux server

## Get started

1. Create a DNS record that points to the public IP address of the Linux server for your SCIM bridge. For example, `scim.example.com`.

2. [Install Docker Engine](https://docs.docker.com/engine/install/#server) on the server (follow the Server instructions; Docker Desktop is not needed). We also recommend following the [post-install steps](https://docs.docker.com/engine/install/linux-postinstall/) as noted in the documentation to enable runing Docker as a non-root user and ensure that Docker Engine automatically starts when the Linux system boots.

3. All following steps can be run directly on the Linux server, or by connecting remotely using the `--host` parameter or `docker context`. If you are already using SSH to connect to the Linux server, you can create and use a Docker context on your local computer that is connected to your 1Password account (these commands require Docker Engine or Docker Desktop to be installed on your computer).

   *Example commands:*

   ```sh
   docker context create op-scim-bridge \
       --description "1Password SCIM Bridge Docker host" \
       --docker host=ssh://user@scim.example.com
   docker context use op-scim-bridge
   ```

   Replace `user` with the correct username for your Linux server and `scim.example.com` with its host name before running the above commands.

4. Initialize a swarm. Run this command:

   ```sh
   docker swarm init # --advertise-addr 192.0.2.1
   ```

   > **Note**
   >
   > If Docker returns an error about multiple network interfaces, uncommment the `--advertise-addr` parameter with the same public IP address of the Linux server as the DNS record.

5. Clone this repository and switch to this directory:

    ```sh
    git clone https://github.com/1Password/scim-examples.git
    cd ./scim-examples/beta/docker
    ```

6. Save your `scimsesion` file to the working directory.

   > **Note**
   >
   > If you are deploying SCIM bridge directly on the Linux server, you will need to transfer the `scimsession` file
   > from your local machine that is signed in to your 1Password account, for example:
   >
   > ```sh
   > scp ./scimsession user@host:scim-examples/beta/docker/scimsession
   > ```

### Configure 1Password SCIM bridge to connect to Google Workspace

If integrating 1Password with Google Workspace, additional cofiguration is required. See [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) for instructions to create the service account, key, and API client.

1. Copy the Google Workspace service account key to the working directory.

   > **Note**
   >
   > If you are deploying SCIM bridge directly on a remote Docker host, you will need to transfer the Workspace credentials file
   > from your local machine that is signed in to your 1Password account, for example:
   >
   > ```sh
   >  scp local/path/to/workspace-credentials.json user@host:scim-examples/beta/docker/workspace-credentials.json
   > ```

2. Copy the [settings file template](/beta/workspace-settings.json) from this repository:

    ```sh
    cp ../workspace-settings.json ./workspace-settings.json
    ```

    Edit the file. Replace the values for each key:

    - `actor`: the email address for the administrator that the service account is acting on behalf of
    - `bridgeAddress`: the URL for your SCIM bridge based on the DNS record created in [Get started](#get-started)

    ```json
    {
        "actor":"admin@example.com",
        "bridgeAddress":"https://scim.example.com"
    }
    ```

    Save the file.

## Deploy 1Password SCIM bridge

After the DNS record has propagated, set the DNS name for your SCIM bridge inline, use the template to output a canonical configuration that will create a Docker Swarm Secret and deploy SCIM bridge, then create the stack from this configuration. You SCIM bridge should automatically acquire and manage a TLS certificate from Let's Encrypt on your behlaf using the supplied domain name.

*Example command:*

```sh
OP_TLS_DOMAIN=scim.example.com docker stack config --compose-file ./compose.template.yaml |
    docker stack deploy --compose-file - op-scim-bridge
```

Replace `scim.example.com` with the domain name that points to your Linux server, then run the command to deploy your SCIM bridge.

### Connect your SCIM bridge to Google Workspace

If you are integrating with Google Workspace, use `compose.gw.yaml` to create the additional Docker Swarm Secrets needed for Workspace.

*Example command:*

```sh
OP_TLS_DOMAIN=scim.example.com docker stack config \
    --compose-file ./compose.template.yaml \
    --compose-file ./compose.gw.yaml |
        docker stack deploy --compose-file - op-scim-bridge
```

Replace `scim.example.com` with the DNS name that points to your Linux server, then run the command to deploy SCIM bridge with access to the required configuration and credentials.

## Test your SCIM bridge

Run this command to retrieve logs from the service for the SCIM bridge container:

```sh
docker service logs op-scim-bridge_scim
```

You can sign in to the URL of your SCIM bridge based on its fully qualified domain name (for example, <https://scim.example.com/>). Sign in with the bearer token for your SCIM bridge to test the connection, view status information, or retrieve logs.

You can also send an authenticated SCIM API request to your SCIM bridge from the command line.

*Example command:*

```sh
curl --header "Authorization: Bearer mF_9.B5f-4.1JqM" https://scim.example.com/Users
```

Replace `mF_9.B5f-4.1JqM` with your bearer token and `scim.example.com` with the domain name of your SCIM bridge in the example above.

> **Note**
   >
   > 💻 If you saved your bearer token as an item in your 1Password account, you can [use 1Password CLI to pass the
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

### Update 1Password SCIM bridge

Update you SCIM bridge to the latest version by updating its service definition:

```sh
docker service update op-scim-bridge_scim --image 1password/scim:v2.8.2
```

### Troubleshooting

If you transferred any files to the Linux server to use for Docker secrets, you may need to change the file permissions to allow Docker to read the file. For example:

```sh
chmod 644 ./scimsession
```
