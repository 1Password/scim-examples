# Deploying the 1Password SCIM Bridge using Docker Swarm

This example describes deploying the 1Password SCIM bridge using Docker Swarm. These instructions require a remote Docker Swarm cluster be set up and configured to be accessed by the Docker CLI.

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Docker cluster. _Do not attempt to perform a provisioning sync before the DNS records have been propogated_. The record must exist and the SCIM bridge server must be running in order for LetsEncrypt to issue a certificate.

## Create your scimsession file

Use the [scim-setup.sh](https://github.com/1Password/scim-examples/tree/master/scim-setup.sh) script while connected to the Docker host on your local machine to set up your account and generate a `scimsession` file. This script uses a Docker container to run the `op-scim setup` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console. Save your bearer token, as it will be needed to authenticate with your IdP.

The scimsession file is equivalent to your Master Password and Secret Key when combined with the bearer token, therefore they should never be stored in the same place.

Example:
```
scim-setup.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```

## Deploy the SCIM bridge

Once your scimsession file has been created, copy it into this directory (next to docker-compose.yml), as we need to populate a Docker Swarm secret in order to securely deploy your scimsession. `generate-secret.sh` will create a secret called `scimsession`, which the op-scim container will then read from `/run/secrets`, as defined in docker-compose.yml.

Next, edit `docker-compose.yml`, replacing `{YOUR-DOMAIN-HERE}` with the domain name indicated by the DNS record created for your SCIM bridge. This will configure LetsEncrypt to automatically issue a certificate for your bridge.

Running `docker stack deploy -c docker-compose.yml op-scim` will now create a container from the `1password/scim` image. A redis container will also be started automatically to be used by the SCIM bridge. _After the DNS record has been propogated_, you can continue setting up your IdP with the SCIM bridge Administration Guide while monitoring the logs from the bridge on your local machine using `docker service logs -f op-scim_scim`.