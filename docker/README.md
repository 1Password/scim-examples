# Deploying the 1Password SCIM Bridge using Docker

This example describes the methods of deploying the 1Password SCIM Bridge using Docker. The Docker Compose and Docker Swarm managers are available and deployment using each manager is described below.


## Preparing

Please ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.


## Docker Compose vs Docker Swarm

Using Docker, you have two different deployment options: `docker-compose` and Docker Swarm.

Docker Swarm is the recommended option. While setting up Swarm is beyond the scope of this documentation, you can either set one up on your own infrastructure, or on a cloud provider of your choice.

While Docker Compose is useful for testing, it is not recommended for use in a production environment. The `scimsession` file is passed into the docker container via an environment variable, which is less secure than Docker Swarm secrets, Kubernetes secrets, or AWS Secrets Manager, all of which are supported and recommended for production use.


## Install Docker tools

Install [Docker for Desktop](https://www.docker.com/products/docker-desktop) on your local machine and _start Docker_ before continuing, as it will be needed to continue with the deployment process.

You'll also need to install `docker-compose` and `docker-machine` command line tools for your platform.

For macOS users who use Homebrew, ensure you're using the _cask_ app-based version of Docker, not the default CLI version. (i.e: `brew cask install docker`)


## Setting up Docker

### Docker Swarm

For this, you will need to have joined a Docker Swarm with the target deployment node. Please refer to [the official Docker documentation](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/) on how to do that.

Once set up and you've logged into your Swarm with `docker swarm join` or created a new one with `docker swarm init`, it's recommended to use the provided the bash script [./docker/deploy.sh](deploy.sh) to deploy your SCIM Bridge.

The script will do the following:

1. Add your `scimsession` file as a Docker Secret within your Swarm cluster.
2. Prompt you for your SCIM Bridge domain name which will configure LetsEncrypt to automatically issue a certificate for your Bridge. This is the domain you selected in [PREPARATION.md](/PREPARATION.md).
3. Deploy a container using `1password/scim`, and a `redis` container. The `redis` container is necessary to store LetsEncrypt certificates.

The logs from the SCIM Bridge and redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point you should set the DNS record for the domain name you prepared to the IP address of the `op-scim` container. You can also continue setting up your Identity Provider at this point.


### Docker Compose

You will need to have a Docker machine set up either locally or remotely. Refer to [the docker-compose documentation](https://docs.docker.com/machine/reference/create/) on how to do that. For a local installation, you can use the `virtualbox` driver.

Once set up, ensure your environment is set up with `eval %{docker-machine env $machine_name}`, with whatever machine name you decided upon.

Run the [./docker/deploy.sh](deploy.sh) script as in the previous example.


### Manual Instructions

#### Cloning `scim-examples`

As seen in [PREPARATION.md](/PREPARATION.md), you’ll need to clone this repository using `git` into a directory of your choice.

```bash
git clone https://github.com/1Password/scim-examples.git
```

You can then browse to the Docker directory:

```bash
cd scim-examples/docker/
```


#### Creating the `scim.env` file

The `scim.env` file contains two environment variables:

* `OP_SESSION` (mandatory for Docker Compose) - a `base64` encoded string of your `scimsession` file
* (OPTIONAL) `OP_LETSENCRYPT_DOMAIN` (for Docker Compose and Docker Swarm) - if set, it initiates a LetsEncrypt challenge to have your SCIM Bridge issued a valid SSL certificate, provided the DNS record is set to its IP

To take advantage of the complimentary LetsEncrypt SSL certificate service, set the variable in the `scim.env` file:
```bash
# change ‘op-scim.example.com’ to match the domain name you’ve set aside for your SCIM Bridge
echo “OP_LETSENCRYPT_DOMAIN=op-scim.example.com” > scim.env
```

Alternatively, setting this variable to blank (i.e: `OP_LETSENCRYPT_DOMAIN=`) will cause the SCIM Bridge to start on port 3002. This is useful if you have a custom load balancer you want to use to terminate SSL connections rather than using LetsEncrypt. Otherwise, you should be sure to set it. This is an “advanced” option so please only try this if you are familiar with setting up your own load balancer:

```bash
# ADVANCED: if you have your own load balancer
echo “OP_LETSENCRYPT_DOMAIN=” > scim.env
```

When using Docker Compose, you can create the environment variable `OP_SESSION` manually by doing the following:

```bash
# only needed for Docker Compose - use Docker Secrets when using Swarm
SESSION=$(cat /path/to/scimsession | base64 | tr -d "\n")
echo "OP_SESSION=$SESSION" >> scim.env
```

On Windows, you can refer to the [./docker/compose/generate-env.bat](generate-env.bat) file on how to generate the `base64` string for `OP_SESSION`.

Check that the `scim.env` file only has two entries (in total) - `OP_LETSENCRYPT_DOMAIN` and/or `OP_SESSION`.


#### Docker Compose

To use Docker Compose to deploy:

```bash
# enter the compose directory
cd scim-examples/docker/compose/
# copy the scim.env file
cp ../scim.env ./
# create the container
docker-compose -f docker-compose.yml up --build -d
# (optional) view the container logs
docker-compose -f docker-compose.yml logs -f
```


#### Docker Swarm

To use Docker Swarm to deploy, you’ll want to have run `docker swarm init` or `docker swarm join` on the target node and completed that portion of the setup. Refer to Docker’s documentation for more details.

Once that’s set up, you can do the following:

```bash
# enter the swarm directory
cd scim-examples/docker/swarm/
# sets up a Docker Secret on your Swarm
cat /path/to/scimsession | docker secret create scimsession -
# copy the scim.env file
cp ../scim.env ./
# deploy your Stack
docker stack deploy -c docker-compose.yml op-scim
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```


### Upgrading

Upgrading the SCIM Bridge should be relatively simple.

First, you `git pull` the latest versions from this repository. Then, you re-apply the `.yml` file.

```bash
cd scim-examples/
git pull
cd docker/{swarm or compose}/
docker-compose -f docker-compose.yml up --build -d
```

This should seamlessly upgrade your SCIM Bridge to the latest version. The process takes about 2-3 minutes for the Bridge to come back online.


### Advanced `scim.env` file options

These should only be used for advanced setups.

* `OP_PORT` - when `OP_LETSENCRYPT_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one of your choosing.
