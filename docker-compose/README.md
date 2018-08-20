# Deploying the 1Password SCIM Bridge using Docker Compose

This example describes the simplest method of deploying the 1Password SCIM bridge, using Docker Compose. These instructions require a remote Docker host be set up and configured to be accessed by the Docker CLI.

Note that this deployment strategy is very useful for testing, but it is not reccomended for use in a production environment. The scimsession file is passed into the container via an environment variable, which is less secure than Docker Swarm secrets or Kubernetes secrets, both of which are supported, and reccomended.

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Docker node. _Do not attempt to perform a provisioning sync before the DNS records have been propogated_. The record must exist and the SCIM bridge server must be running in order for LetsEncrypt to issue a certificate.

## Create your scimsession file

Use the Linux Bash [create-session-file.sh](../session/create-session-file.sh) script or Windows PowerShell [create-session-file.bat](../session/create-session-file.bat) batch file while connected to the Docker host on your local machine to create a scimsession file. This script uses a Docker container to run the `op-scim init` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console. Save your bearer token, as it will be needed to authenticate with your IdP.

The scimsession file is equivalent to your Master Password and Secret Key when combined with the bearer token, therefore they should never be stored in the same place.

Example:
```
create-session-file.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```

## Deploy the SCIM bridge

Once your scimsession file has been created, copy it into this directory (next to docker-compose.yml), as we need to populate some ENV variables in the container. Linux Bash `generate-env.sh` script or Windows PowerShell `generate-env.bat` batch file will create a `scim.env` file, allowing docker-compose to pass the scimsession file into the container without writing it to the container filesystem, leading to insecure storage of the file. The scimsession is base64 encoded before being put into the .env file.

Next, edit `docker-compose.yml`, replacing `{YOUR-DOMAIN-HERE}` with the domain name indicated by the DNS record created for your SCIM bridge. This will configure LetsEncrypt to automatically issue a certificate for your bridge.

Running `docker-compose up --build` will now create a container from the `1password/scim` image. A redis container will also be started automatically to be used by the SCIM bridge. _After the DNS record has been propogated_, you can continue setting up your IdP with the SCIM bridge Administration Guide while monitoring the logs from the bridge on your local machine.

Once you have tested the configuration, the bridge can be exited using ctrl/cmd-c, and restarted in daemon mode using `docker-compose up -d, or deployed for production use with Docker Swarm or Kubernetes. You can access logs using `docker-compose logs` at any point in the future.

## Automatically starting the SCIM bridge upon startup

In order to automatically launch the 1Password SCIM bridge upon startup when using docker-compose you'll need to automatically start the Docker daemon, then start op-scim.

### Systemd

1. Install the service file for op-scim. A [sample](op-scim.service) is provided and you'll need to change the path.
2. Reload systemd: `systemctl daemon-reload`
3. Enable the op-scim service: `systemctl enable op-scim`

