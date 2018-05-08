# Deploying the 1Password SCIM Bridge using Docker Compose

This example describes the simplest method of deploying the 1Password SCIM bridge, using Docker Compose. These instructions require a remote Docker host be set up and configured to be accessed by the Docker CLI.

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Docker node. _Do not attempt to perform a provisioning sync before the DNS records have been propogated_. The record must exist and the SCIM bridge server must be running in order for LetsEncrypt to issue a certificate.

## Create your scimsession file

Use the [create-session-file.sh](https://github.com/1Password/scim-examples/tree/master/session) script on your local machine to create a scimsession file. This script uses a Docker container to run the `op-scim init` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console. Save your bearer token, as it will be needed to authenticate with your IdP.

The scimsession file is equivalent to your account key and master password when combined with the bearer token, therefore they should never be stored in the same place.

Example:
```
create-session-file.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```

## Deploy the SCIM bridge

Once your scimsession file has been created, copy it into this directory (next to the Dockerfile and docker-compose.yml), as it will be copied into your container at build time.

Next, edit `docker-compose.yml`, replacing `{YOUR-DOMAIN-HERE}` with the domain name indicated by the DNS record created for the SCIM bridge. This will configure LetsEncrypt to automatically issue a certificate for your bridge.

Running `docker-compose up --build` will now create a new container with `onepassword/scim` as the base image. A redis container will also be started automatically to be used by the SCIM bridge. _After the DNS record has been propogated_, you can continue setting up your IdP with the SCIM bridge Administration Guide while monitoring the logs from the bridge on your local machine.

Once you have tested the configuration, the bridge can be exited using ctrl/cmd-c, and restarted in daemon mode for permanent use. `docker-compose up -d` will re-deploy the containers, allowing you to access logs using `docker-compose logs` at any point in the future.