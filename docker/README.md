# Deploying the 1Password SCIM Bridge using Docker

This example describes the methods of deploying the 1Password SCIM bridge using Docker. The Docker Compose and Docker Swarm managers are available and deployment using each manager is described below.

## Preparing

Please ensure you've read through the [Preparing](https://github.com/1Password/scim-examples/tree/master/PREPARING.md) document before beginning deployment.


## Install Docker locally

Install [Docker for Desktop](https://www.docker.com/products/docker-desktop) on your local machine and _start Docker_ before continuing, as it will be needed to continue with the deployment process.

For macOS users who use Homebrew, ensure you're using the _cask_ app-based version of Docker, not the default CLI version.


## Docker Compose vs Docker Swarm

Using Docker, you have two different deployment options: `docker-compose` and Docker Swarm.

Docker Swarm is the recommended option. _Please refer to your cloud provider on how to setup a remote Docker Swarm Cluster if you do not have one set up already or are experiencing difficulties doing so._

`docker-compose` is very useful for testing, but it is not recommended for use in a production environment. The `scimsession` file is passed into the docker container via an environment variable, which is less secure than Docker Swarm secrets or Kubernetes secrets, both of which are supported, and recommended.


## Deploy SCIM bridge

Connect to your remote Docker host from your local machine using the following:

```
eval %{docker-machine env dev}
```

It's recommended to use the provided the bash script [./docker/deploy.sh](deploy.sh) to deploy your SCIM bridge. 

If you cloned this repo on your remote machine using SSH, you should copy the `scimsession` file to the `scim-examples` folder on your server. 

The script will do the following:

1. Ask if you want to deploy with Docker Swarm or Compose
2. Add your `scimsession` to the SCIM bridge container, using a .env file for Docker Compose or a swarm secret for Docker Swarm.
3. Prompt you for your SCIM bridge domain name which will configure LetsEncrypt to automatically issue a certificate for your bridge. This is the domain you selected in [Preparing](https://github.com/1Password/scim-examples/tree/master/PREPARING.md).
4. Deploy a container using `1password/scim`, and a redis container. The redis container is necessary to store LetsEncrypt certificates.

The logs from the SCIM bridge and redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point you should set the DNS record for the domain name you selected to the IP address of the op-scim container. You can continue setting up your Identity Provider with the SCIM Bridge Administration Guide.


### Additional Docker Compose instructions

This only applies when using and testing the SCIM bridge through `docker-compose`.

In order to automatically launch the 1Password SCIM bridge upon startup when using `docker-compose`, you will need to configure systemd to automatically start the Docker daemon and launch op-scim.

1. Install the service file for op-scim. A [sample](compose/op-scim.service) is provided and you'll need to modify it to your needs.
2. Once installed, reload systemd so that it recognizes the service: `systemctl daemon-reload`
3. Enable the op-scim service: `systemctl enable op-scim`
4. Start the op-scim service: `systemctl start op-scim`
