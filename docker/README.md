# Deploying the 1Password SCIM Bridge using Docker
This example describes the methods of deploying the 1Password SCIM bridge using Docker. The Docker Compose and Docker Swarm managers are available and deployment using either managers is described below.

## Docker Compose
This is the simplest method of deploying the SCIM bridge. These instructions require a remote Docker host be set up and configured to be accessed by the Docker CLI. _Please refer to your cloud storage provider on how to setup a remote Docker host if you do not have one set up already or are experiencing difficulties doing so._

**Note that this deployment strategy is very useful for testing, but it is not recommended for use in a production environment. The scimsession file is passed into the docker container via an environment variable, which is less secure than Docker Swarm secrets or Kubernetes secrets, both of which are supported, and recommended.**

## Docker Swarm
These instructions require a remote Docker Swarm cluster be set up and configured to be accessed by the Docker CLI. _Please refer to your cloud storage provider on how to setup a remote Docker Swarm Cluster if you do not have one set up already or are experiencing difficulties doing so._

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Docker node. _Do not attempt to perform a provisioning sync before the DNS records have been propogated_. The DNS record must exist and the SCIM bridge server must be running in order for LetsEncrypt to issue a certificate. _Please refer to your cloud storage provider on how to setup a DNS record if you do not have one set up already or are experiencing difficulties doing so._

## Create your scimsession file and Deploy SCIM bridge

1. Connect to your remote Docker host from your local machine

2. Use the Linux Bash [scim-setup.sh](../session/scim-setup.sh) script to authenticate your account and generate a `scimsession` file : This script uses a Docker container to run the `op-scim setup` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console. Save your bearer token, as it will be needed to authenticate with your IdP.

_The scimsession file is equivalent to your Master Password and Secret Key when combined with the bearer token, therefore they should never be stored in the same place._

Example:
```
scim-setup.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```

3. Once your scimsession file has been created, use the Linux Bash `./docker/deploy.sh` script to deploy the SCIM bridge. Have the domain name indicated by the DNS record created for the SCIM bridge ready. This script will do the following :

    1. For `docker-compose`, it generate a `scim.env` file that allows the scimsession file to be passed into the container without insecurely writing it to the container filesystem. For `docker-swarm`, it will create a secret called `scimsession`, which the op-scim container will then read from `/run/secrets`, as defined in docker-compose.yml.

    1. The domain name entered will configure LetsEncrypt to automatically issue a certificate for your bridge.

    1. Lastly, it will create a container from the `1password/scim` image. A redis container will also be started automatically to be used by the SCIM bridge.

_After the DNS record has been propogated_, you can continue setting up your IdP with the SCIM bridge Administration Guide while monitoring the logs from the bridge on your local machine.

In order to automatically launch the 1Password SCIM bridge upon startup when using **docker-compose** you'll need to automatically start the Docker daemon, then start op-scim.

### Systemd

1. Install the service file for op-scim. A [sample](op-scim.service) is provided and you'll need to change the path.
2. Reload systemd: `systemctl daemon-reload`
3. Enable the op-scim service: `systemctl enable op-scim`
