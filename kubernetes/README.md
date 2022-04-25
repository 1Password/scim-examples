# Deploying the 1Password SCIM bridge on Kubernetes

This example explains how to deploy the 1Password SCIM bridge on a Kubernetes cluster. It assumes your Kubernetes cluster supports "load balancer" services.

You can modify this deployment to suit your environment and needs.

If you are deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

The deployment process consists of these steps:

1. Create a Kubernetes secret with your `scimsession` file
2. Configure the SCIM bridge (through the `op-scim-config.yaml` file)
3. Deploy the SCIM bridge and Redis services
4. Set up DNS entries for your SCIM bridge

## Structure

- `op-scim-deployment.yaml`: The SCIM bridge deployment.
- `op-scim-service.yaml`: Public load balancer for the SCIM bridge server.
- `op-scim-config.yaml`: Configuration for the SCIM bridge server. You’ll be modifying this file during the deployment.
- `redis-config.yaml`: [(optional*)](#external-redis-server) Configuration for the redis deployment.
- `redis-deployment.yaml`:  [(optional*)](#external-redis-server) A redis server deployment.
- `redis-service.yaml`:  [(optional*)](#external-redis-server) Kubernetes service for the redis deployment.

## Preparing

Ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.

## Clone `scim-examples`

As seen in [PREPARATION.md](/PREPARATION.md), you’ll need to clone this repository using `git` into a directory of your choice.

```bash
git clone https://github.com/1Password/scim-examples.git
```

You can then browse to the Kubernetes directory:

```bash
cd scim-examples/kubernetes/
```

## Create the Kubernetes secret

The following requires that you’ve completed the initial setup of Provisioning in your 1Password Account. [See here](https://support.1password.com/scim/#step-1-prepare-your-1password-account) for more details.

Once complete, you must create a Kubernetes secret containing the `scimsession` file. Using `kubectl`, we can read the `scimsession` file and create the Kubernetes secret in one command:

```bash
kubectl create secret generic scimsession --from-file=/path/to/scimsession
```

## Configuring the SCIM bridge

You'll need to edit the `op-scim-config.yaml` file and change the variable `OP_LETSENCRYPT_DOMAIN` to the domain you've decided on for your SCIM bridge. This allows LetsEncrypt to issue your deployment an SSL certificate necessary for encrypted traffic.

## Deploy to the Kubernetes cluster

Run the following `kubectl` command to complete your deployment. It will deploy the both the `redis` server and the `op-scim` app.

```bash
cd scim-examples/kubernetes/
kubectl apply -f .
```

## Configuring the DNS entries

The Kubernetes deployment creates a public load balancer in your environment pointing to the SCIM bridge.

To get its public IP address:

```bash
kubectl describe service/op-scim-bridge 
# look for ‘LoadBalancer Ingress’
```

It can take some time before the public address becomes available.

At this stage, you can finish configuring your DNS entry as outlined in [PREPARATION.md](/PREPARATION.md).

## Testing the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account.

You can do this with `curl`, as an example:

```bash
curl --header "Authorization: Bearer TOKEN_GOES_HERE" https://<domain>/scim/Users
```

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM bridge.

## Upgrading

To upgrade your SCIM bridge, follow these steps:

```bash
cd scim-examples/
git pull
cd kubernetes/
kubectl apply -f .
```

This will upgrade your SCIM bridge to the latest version, which should take about 2-3 minutes for Kubernetes to process.

### October 2020 Upgrade Changes

As of October 2020, the `scim-examples` Kubernetes deployment now uses `op-scim-config.yaml` to set the configuration needed for your SCIM bridge, and has changed the deployment names from `op-scim` to `op-scim-bridge`, and `redis` to `op-scim-redis` for clarity and consistency. 

You’ll need to re-configure your options in `op-scim-config.yaml`, particularly `OP_LETSENCRYPT_DOMAIN`. You may also want to delete your previous `op-scim` and `redis` deployments to prevent conflict between the two versions.

```bash
kubectl delete deployment/op-scim deployment/redis
kubectl apply -f .
```

You’ll then need to update your SCIM bridge’s domain name DNS record. You can find the IP for that with:

```bash
kubectl describe service/op-scim-bridge
# look for ‘LoadBalancer Ingress’
```

This is a one-time operation to change the deployment and service names of the SCIM bridge so they are more easily identifiable to administrators.

### April 2021 Upgrade Changes (SCIM bridge 2.0)

With the release of SCIM bridge 2.0, the environment variables `OP_REDIS_HOST` and `OP_REDIS_PORT` have been deprecated and in favour of `OP_REDIS_URL`. Ensure that your `op-scim-config.yaml` file has changed to reflect this new environment variable, and reapplied to your pods with:

```bash
cd scim-examples/kubernetes
git pull
kubectl delete configmaps op-scim-configmap
kubectl apply -f .
kubectl scale deploy op-scim-bridge --replicas=0 && sleep 3 && kubectl scale deploy op-scim-bridge --replicas=1
```

## Advanced deployments

The following are helpful tips in case you wish to perform an advanced deployment.

### External load balancer

In `op-scim-config.yaml`, you can set the `OP_LETSENCRYPT_DOMAIN` variable to blank, which will have the SCIM bridge serve on port 3002. You can then map your pre-existing webserver (Apache, NGINX, etc). You will no longer be issued a certificate by LetsEncrypt.

### External redis server

If you are using an existing redis instance that's not running on `redis://redis:6379`, you can change the `OP_REDIS_URL` variable in `op-scim-config.yaml`.

You would then omit the the `redis-*.yaml` files when deploying to your Kubernetes cluster.

### Human-Readable Logs

You can set `OP_PRETTY_LOGS` to `1` if you would like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren’t planning on doing custom log ingestion in your environment.

### Debug Mode

You can set `OP_DEBUG` to `1` to enable debug output in the logs. Useful for troubleshooting or when contacting 1Password Support.

### Health Check Ping Server

When using Let’s Encrypt on some Kubernetes clusters, health checks can fail for the SCIM bridge before the bridge is able to obtain a Let’s Encrypt certificate.

You can set `OP_PING_SERVER` to `1` to enable a `/ping` endpoint on port `80` so that health checks will always be brought online. For security reasons, no other endpoints (such as `/scim`) are exposed through this port.

The endpoint is disabled if `OP_LETSENCRYPT_DOMAIN` is set to blank and TLS is not utilized.

