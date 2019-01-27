# Deploying the 1Password SCIM Bridge using Docker Compose

This example describes the simplest method of deploying the 1Password SCIM bridge, using Docker Compose. These instructions require a remote Docker host be set up and configured to be accessed by the Docker CLI. _Please refer to your cloud storage provider on how to setup a remote Docker host if you do not have one set up already._

Note that this deployment strategy is very useful for testing, but it is not recommended for use in a production environment. The scimsession file is passed into the docker container via an environment variable, which is less secure than Docker Swarm secrets or Kubernetes secrets, both of which are supported, and recommended.

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Docker node. _Do not attempt to perform a provisioning sync before the DNS records have been propogated_. The record must exist and the SCIM bridge server must be running in order for LetsEncrypt to issue a certificate. _Please refer to your cloud storage provider on how to setup a DNS record if you do not have one set up already._

## Create your scimsession file and Deploy SCIM bridge

1. Connect to your remote Docker host from your local machine

1. Use the Linux Bash [scim-setup.sh](../session/scim-setup.sh) script to authenticate your account and generate a `scimsession` file : This script uses a Docker container to run the `op-scim setup` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console. Save your bearer token, as it will be needed to authenticate with your IdP.

_The scimsession file is equivalent to your Master Password and Secret Key when combined with the bearer token, therefore they should never be stored in the same place._

Example:
```
scim-setup.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```

1. Once your scimsession file has been created, use the Linux Bash `build.sh` script to deploy the SCIM bridge. Have the domain name indicated by the DNS record created for the SCIM bridge ready. This script will do the following :

    1. For `docker-compose`, it generate a `scim.env` file that allows the scimsession file to be passed into the container without insecurely writing it to the container filesystem. For `docker-swarm`, it will create a secret called `scimsession`, which the op-scim container will then read from `/run/secrets`, as defined in docker-compose.yml.

    1. The domain name entered will configure LetsEncrypt to automatically issue a certificate for your bridge.

    1. Lastly, it will create a container from the `1password/scim` image. A redis container will also be started automatically to be used by the SCIM bridge.

_After the DNS record has been propogated_, you can continue setting up your IdP with the SCIM bridge Administration Guide while monitoring the logs from the bridge on your local machine.