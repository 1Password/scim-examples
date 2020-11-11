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

### Automatic Instructions

#### Docker Swarm

For this, you will need to have joined a Docker Swarm with the target deployment node. Please refer to [the official Docker documentation](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/) on how to do that.

Once set up and you've logged into your Swarm with `docker swarm join` or created a new one with `docker swarm init`, it's recommended to use the provided the bash script [./docker/deploy.sh](deploy.sh) to deploy your SCIM Bridge.

The script will do the following:

1. Add your `scimsession` file as a Docker Secret within your Swarm cluster.
2. Prompt you for your SCIM Bridge domain name which will configure LetsEncrypt to automatically issue a certificate for your Bridge. This is the domain you selected in [PREPARATION.md](/PREPARATION.md).
3. Deploy a container using `1password/scim`, and a `redis` container. The `redis` container is necessary to store LetsEncrypt certificates.

The logs from the SCIM Bridge and redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point you should set the DNS record for the domain name you prepared to the IP address of the `op-scim` container. You can also continue setting up your Identity Provider at this point.

#### Docker Compose

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

#### Docker Compose

When using Docker Compose, you can create the environment variable `OP_SESSION` manually by doing the following:

```bash
# only needed for Docker Compose - use Docker Secrets when using Swarm
# enter the ‘compose’ directory within `scim-examples/docker/`
cd compose/
SESSION=$(cat /path/to/scimsession | base64 | tr -d "\n")
sed -i '' -e "s/OP_SESSION=$/OP_SESSION=$SESSION/" compose/scim.env
```

You’ll also need to set the environment variable `OP_LETSENCRYPT_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_LETSENCRYPT_DOMAIN` to that domain name.

And finally, use `docker-compose` to deploy:

```bash
# enter the compose directory
cd scim-examples/docker/compose/
# create the container
docker-compose -f docker-compose.yml up --build -d
# (optional) view the container logs
docker-compose -f docker-compose.yml logs -f
```

#### Docker Swarm

To use Docker Swarm to deploy, you’ll want to have run `docker swarm init` or `docker swarm join` on the target node and completed that portion of the setup. Refer to Docker’s documentation for more details.

Unlike Docker Compose, you won’t need to set the `OP_SESSION` variable in `scim.env`, as we’ll be using Docker Secrets to store the `scimsession` file.

You’ll still need to set the environment variable `OP_LETSENCRYPT_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_LETSENCRYPT_DOMAIN` to that domain name.

Once that’s set up, you can do the following:

```bash
# enter the swarm directory
cd scim-examples/docker/swarm/
# sets up a Docker Secret on your Swarm
cat /path/to/scimsession | docker secret create scimsession -
# deploy your Stack
docker stack deploy -c docker-compose.yml op-scim
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```

### Testing

To test if your SCIM Bridge came online, you can browse to the public IP address of your SCIM Bridge’s Docker Host with a web browser, and input your Bearer Token into the provided Bearer Token field.

You can also use the following `curl` command to test the SCIM Bridge from the command line:

```bash
curl --header "Authorization: Bearer TOKEN_GOES_HERE" https://<domain>/scim/Users
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

#### October 2020 Update

As of October 2020, if you’re upgrading from a previous version of the repository, ensure that you’ve reconfigured your environment variables within `scim.env` before upgrading.

### Advanced `scim.env` file options

These should only be used for advanced setups.

* `OP_PORT` - when `OP_LETSENCRYPT_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one of your choosing.
* `OP_REDIS_HOST` - you can specify either a hostname or IP address here to point towards an alternative redis host. You can then strip out the sections in `docker-compose.yml` that refer to redis to not deploy that container. Note that redis is still required for the SCIM Bridge to function.

#### Generating `scim.env` file on Windows

On Windows, you can refer to the [./docker/compose/generate-env.bat](generate-env.bat) file on how to generate the `base64` string for `OP_SESSION`.
