# Docker Compose v2

## Prerequisites

- Linux server with port 443 open
- Docker Engine (see [Docker Engine installation overview](https://docs.docker.com/engine/install/#server))
- Docker Compose (see [Install Docker Compose](https://docs.docker.com/compose/install/))

> **Note:**
>
> This deployment example assumes Docker Compose is run locally on the Docker
> host. Deploying remotely (i.e. using `docker context`) is _not_ supported.

## Get started

1. Create a DNS record that points to your Docker host, e.g. `scim.example.com`.

2. Clone this repository and switch to this directory:

    ```sh
    git clone https://github.com/1Password/scim-examples.git
    cd ./scim-examples/beta/docker/compose
    ```

3. Copy your `scimsesion` file to this working directory, e.g.:

    ```sh
    cp path/to/scimsession ./scimsession
    ```

4. Create a canonical configuration (replace `scim.example.com` with the DNS record from Step 1):

    ```sh
    OP_LETSENCRYPT_DOMAIN=scim.example.com docker compose -f compose.template.yaml convert > compose.yaml
    ```

### Configure 1Password SCIM bridge to connect to Google Workspace

If integrating 1Password with Google Workspace, additional cofiguration is required. See [Connect Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client) for instructions to create the service account, key, and API client.

1. Copy the Google Workspace service account key to this working directory, i.e.:

    ```sh
     cp path/to/workspace-credentials.json ./workspace-credentials.json
     ```

2. Copy the [settings file template](/beta/workspace-settings.json) to this directory:

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

3. Update the canonical configuration for SCIM bridge to include the overlay configuration for Google Workspace (replace `scim.example.com` with the DNS record for your SCIM bridge):

    ```sh
    OP_LETSENCRYPT_DOMAIN=scim.example.com docker compose -f compose.template.yaml -f compose.gw.yaml convert > compose.yaml
    ```

## Deploy 1Password SCIM bridge

After the DNS record has propagated, deploy 1Password SCIM bridge using Docker Compose:

```sh
docker compose up -d
```

## Appendix

### Update 1Password SCIM bridge

You can monitor the [1Password SCIM bridge release notes](https://app-updates.agilebits.com/product_history/SCIM) page to see the latest version.

To update your SCIM bridge, switch to this directory, pull the latest version of this repository, and apply the updated `.yaml` (replace `scim.example.com` with the DNS record pointing to your SCIM bridge):

```sh
cd scim-examples/beta/docker
git pull
OP_LETSENCRYPT_DOMAIN=scim.example.com docker compose -f compose.template.yaml [-f compose.gw.yaml] convert > compose.yaml
docker compose up -d
```

### Use regenerated credentials

If you want to use a new bearer token or `scimsession` file, [visit the Integrations page](https://start.1password.com/integrations/provisioning) at 1Password.com and click Regenerate Credentials. Copy the new `scimsession` file to the Docker host and restart SCIM bridge, e.g.:

```sh
cd scim-examples/beta/docker
cp path/to/scimsession ./scimsession
docker compose restart scim
```

The bearer token and `scimsession` file are cryptographically linked. Update the configuration in your identity provider to use the new bearer token.

### Change the DNS name

To use a new DNS name for your SCIM bridge, create a new record pointing to your bridge, wait for it to propagate, then redeploy, i.e.:

```sh
cd scim-examples/beta/docker
OP_LETSENCRYPT_DOMAIN=new-name.example.com docker compose -f compose.template.yaml [-f compose.gw.yaml] convert > compose.yaml
docker compose up -d
```
