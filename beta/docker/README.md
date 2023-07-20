# Docker Compose v2

## Prerequisites

- Linux server supporting Docker Engine
- Docker Engine (v20.10.3+) (see [Docker Engine installation overview](https://docs.docker.com/engine/install/#server))
- Docker Compose (v2.0+) (see [Install Docker Compose](https://docs.docker.com/compose/install/))
- public DNS record pointing to the Docker host

## Get started

1. Create a DNS record that points to your Docker host, e.g. `scim.example.com`.

2. Clone this repository and switch to this directory:

    ```sh
    git clone https://github.com/1Password/scim-examples.git
    cd ./scim-examples/beta/docker
    ```

3. Initialize the Docker Swarm. Run this command on your Docker host:

   ```sh
   docker swarm init
   ``````

4. Copy your `scimsesion` file to the working directory.

   > **Note**
   >
   > If you are deploying SCIM bridge directly on a remote Docker host, you will need to transfer the `scimsession` file
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

After the DNS record has propagated, set the DNS name for your SCIM bridge configuration and pipe the templated configuration to create a Docker Swarm Secret and deploy SCIM bridge.

*Example command:*

```sh
   OP_TLS_DOMAIN=scim.example.com docker stack config \
       --compose-file ./compose.template.yaml |
           docker stack deploy --compose-file - op-scim-bridge
```

Replace `scim.example.com` with the DNS name that points to your Docker host, then run the command to deploy SCIM bridge.

### Connect your SCIM bridge to Google Workspace

If you are integrating with Google Workspace, you can create the additional Docker Swarm Secrets for Workspace and redeploy your SCIM bridge by merging the `compose.gw.yaml` configuration:

```sh
   OP_TLS_DOMAIN=scim.example.com docker stack config \
       --compose-file ./compose.template.yaml \
       --compose-file ./compose.gw.yaml |
           docker stack deploy --compose-file - op-scim-bridge
```

## Appendix

### Update 1Password SCIM bridge

<!-- TODO -->