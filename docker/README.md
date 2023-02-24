# Deploying the 1Password SCIM bridge using Docker

This example describes the methods of deploying the 1Password SCIM bridge using Docker. The Docker Compose and Docker Swarm managers are available and deployment using each manager is described below.

## Preparing

Ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.

## Docker Compose vs Docker Swarm

Using Docker, you have two different deployment options: `docker-compose` and Docker Swarm.

Docker Swarm is the recommended option, but both options can be used successfully depending on your deployment needs. While setting up a Docker host is beyond the scope of this documentation, you can either set one up on your own infrastructure, or on a cloud provider of your choice.

The `scimsession` file is passed into the docker container via an environment variable, which is less secure than Docker Swarm secrets, Kubernetes secrets, or AWS Secrets Manager, all of which are supported and recommended for production use.

## Install Docker tools

Install [Docker for Desktop](https://www.docker.com/products/docker-desktop) on your local machine and _start Docker_ before continuing, as it will be needed to continue with the deployment process.

You'll also need to install `docker-compose` and `docker-machine` command line tools for your platform.

For macOS users who use Homebrew, ensure you're using the _cask_ app-based version of Docker, not the default CLI version. (i.e: `brew cask install docker`)

## Automatic Deployment Instructions

These steps can be used for automatic deployments using either Docker Swarm or Docker Compose running [./docker/deploy.sh](deploy.sh).

### Docker Swarm

For this, you will need to have joined a Docker Swarm with the target deployment node. Please refer to [the official Docker documentation](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/) on how to do that.

Once set up and you've logged into your Swarm with `docker swarm join` or created a new one with `docker swarm init`, it's recommended to use the provided the bash script [./docker/deploy.sh](deploy.sh) to deploy your SCIM bridge.

The script will do the following:

1. Prompt you if you are using Google Workspace as your Identity Provider and for configuration files locations to add them as a Docker Secrets within your Swarm cluster.
2. Prompt if you are deploying using Docker Swarm or Docker Compose.
3. Prompt you for your SCIM bridge domain name which will configure Let's Encrypt to automatically issue a certificate for your Bridge. This is the domain you selected in [PREPARATION.md](/PREPARATION.md).
4. Prompt you for your `scimsession` file location to add your `scimsession` file as a Docker Secret within your Swarm cluster.
5. Deploy a container using `1password/scim`, and a `redis` container. The `redis` container is necessary to store Let's Encrypt certificates, as well as act as a cache for Identity Provider data.

The logs from the SCIM bridge and Redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point you should set the DNS record for the domain name you prepared to the IP address of the `op-scim` container. You can also continue setting up your Identity Provider at this point.

### Docker Compose

You will need to have a Docker machine set up either locally or remotely. Refer to [the docker-compose documentation](https://docs.docker.com/machine/reference/create/) on how to do that. For a local installation, you can use the `virtualbox` driver.

Once set up, ensure your environment is set up with `eval %{docker-machine env $machine_name}`, with whatever machine name you decided upon.

Run the [./docker/deploy.sh](deploy.sh) script as in the previous example above for Docker Swarm selecting Compose as the deployment method in step 2. Any references for Docker Secrets will be added to the Docker Compose deployment as environment variables.

<hr>

## Manual Deployment Steps

<details>
<summary> Manual Deployment Steps</summary>

### Manual Instructions

These steps can be used for manual deployments using either Docker Swarm or Docker Compose.

### Cloning `scim-examples`

As seen in [PREPARATION.md](/PREPARATION.md), you’ll need to clone this repository using `git` into a directory of your choice.

```bash
git clone https://github.com/1Password/scim-examples.git
```

You can then browse to the Docker directory:

```bash
cd scim-examples/docker/
```

### Docker Swarm

To use Docker Swarm to deploy, you’ll want to have run `docker swarm init` or `docker swarm join` on the target node and completed that portion of the setup. Refer to [Docker’s documentation for more details](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

Unlike Docker Compose, you won’t need to set the `OP_SESSION` variable in `scim.env`, as we’ll be using Docker Secrets to store the `scimsession` file.

You’ll still need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name.

### Information for Google Workspace as your Identity Provider (IdP)
If you’re using Google Workspace as your identity provider for provisioning, you will need to set up some additional secrets to use this functionality as detailed below. Refer to our complete Google Workspace provisioning documentation for more complete information, https://support.1password.com/scim-google-workspace. 

First, edit the file located at `scim-examples/beta/workspace-settings.json` and enter in the appropriate details.

Next, to create the necessary secrets for Google Workspace:

```bash
# this is the path of the JSON file you edited in the paragraph above
cat /path/to/workspace-settings.json | docker secret create workspace-settings -
# replace <google keyfile> with the name of the file Google generated for your Google Service Account
cat /path/to/<google keyfile>.json | docker secret create workspace-credentials -

```
<br>

Once that’s set up, you can do the following (using the alternate command for the stack deployment if using Google Workspace as your Identity Provider):

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

Alternate Google Workspace stack deployment command:

``` bash
# deploy your Stack with Google Workspace settings
docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim
```

### Docker Compose

When using Docker Compose, you can create the environment variable `OP_SESSION` manually by doing the following:

```bash
# only needed for Docker Compose - use Docker Secrets when using Swarm
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
SESSION=$(cat /path/to/scimsession | base64 | tr -d "\n")
sed -i '' -e "s/OP_SESSION=$/OP_SESSION=$SESSION/" ./scim.env
```

You’ll also need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name.

Ensure that `OP_TLS_DOMAIN` is set to the domain name you’ve set up before continuing.

### Information for Google Workspace as your Identity Provider (IdP)
If you’re using Google Workspace as your identity provider for provisioning, you will need to set up some additional secrets to use this functionality as detailed below. Refer to our complete Google Workspace provisioning documentation for more complete information, https://support.1password.com/scim-google-workspace. 

First, edit the file located at `scim-examples/beta/workspace-settings.json` and enter in the appropriate details.
Next, to create the necessary environment variables for Google Workspace:

```bash
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
# this is the path of the JSON file you edited in the paragraph above
wORKSPACE_SETTINGS=$(cat /path/to/workspace_settings.json | base64 | tr -d "\n")
sed -i '' -e "s/OP_WORKSPACE_SETTINGS=$/OP_WORKSPACE_SETTINGS=$WORKSPACE_SETTINGS/" ./scim.env
# replace <google keyfile> with the name of the file Google generated for your Google Service Account
GOOGLE_CREDENTIALS=$(cat /path/to/<google keyfile>.json | base64 | tr -d "\n")
sed -i '' -e "s/OP_WORKSPACE_CREDENTIALS=$/OP_WORKSPACE_CREDENTIALS=$GOOGLE_CREDENTIALS/" ./scim.env
```
<br>

And finally, use `docker-compose` to deploy:

```bash
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
# create the container
docker-compose -f docker-compose.yml up --build -d
# (optional) view the container logs
docker-compose -f docker-compose.yml logs -f
```
</details>
<hr>

## Testing

To test if your SCIM bridge came online, you can browse to the public IP address of your SCIM bridge’s Docker Host with a web browser, and input your Bearer Token into the provided Bearer Token field.

You can also use the following `curl` command to test the SCIM bridge from the command line:

```bash
curl --header "Authorization: Bearer TOKEN_GOES_HERE" https://<domain>/scim/Users
```

## Upgrading

Upgrading the SCIM bridge should be relatively simple.

First, you `git pull` the latest versions from this repository. Then, you re-apply the `.yml` file.

### For Docker Swarm Upgrades:

```bash
cd scim-examples/
git pull
cd docker/swarm/
# For Docker Swarm updates: 
# add second yaml if using Google Workspace `docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim`
docker stack deploy -c docker-compose.yml op-scim
```

### For Docker Compose Upgrades:

```bash
cd scim-examples/
git pull
cd docker/compose/
# for Docker Compose updates:
docker-compose -f docker-compose.yml up --build -d
```

This should seamlessly upgrade your SCIM bridge to the latest version. The process takes about 2-3 minutes for the Bridge to come back online.

#### October 2020 Update

As of October 2020, if you’re upgrading from a previous version of the repository, ensure that you’ve reconfigured your environment variables within `scim.env` before upgrading.

#### April 2021 Update (SCIM bridge 2.0)

With the release of SCIM bridge 2.0, the environment variables `OP_REDIS_HOST` and `OP_REDIS_PORT` have been deprecated in favour of `OP_REDIS_URL`, which takes a full `redis://` or `rediss://` (for TLS) Redis URL. For example: `OP_REDIS_URL=redis://redis:6379`

Unless you have customized your Redis deployment, there shouldn’t be any action you need to take.

## Advanced `scim.env` file options

The following options are available for advanced or custom deployments. Unless you have a specific need, these options do not need to be modified.

* `OP_TLS_CERT_FILE` and `OP_TLS_KEY_FILE` - these two variables can be set to the paths of a key file and certificate file, which then disables Let's Encrypt functionality, causing the SCIM bridge to utilize your own manually-defined certificate when `OP_TLS_DOMAIN` is also defined. Note that this is only supported under Docker Swarm, not under Docker Compose.
* `OP_PORT` - when `OP_TLS_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one of your choosing.
* `OP_REDIS_URL` - you can specify `redis://` or `rediss://` (for TLS) URL here to point towards an alternative Redis host. You can then strip out the sections in `docker-compose.yml` that refer to Redis to not deploy that container. Note that Redis is still required for the SCIM bridge to function.
* `OP_PRETTY_LOGS` - can be set to `1` if you would like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren’t planning on doing custom log ingestion in your environment.
* `OP_DEBUG` - can be set to `1` to enable debug output in the logs. Useful for troubleshooting or when contacting 1Password Support.
* `OP_TRACE` - can be set to `1` to enable Trace-level log output. Useful for debugging Let’s Encrypt integration errors.
* `OP_PING_SERVER` - can be set to `1` to enable an optional `/ping` endpoint on port `80`. Useful for health checks. Disabled if `OP_TLS_DOMAIN` is unset and TLS is not utilized.

## Generating `scim.env` file on Windows

On Windows, you can refer to the [./docker/compose/generate-env.bat](generate-env.bat) file on how to generate the `base64` string for `OP_SESSION`.
