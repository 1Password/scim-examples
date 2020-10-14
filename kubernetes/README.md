# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Password SCIM bridge on a Kubernetes cluster. It assumes your Kubernetes cluster supports "load balancer" services.

You can modify this deployment to suit your environment and needs.

If you are deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

The deployment process consists of these steps:

1. Create the scimsession Kubernetes secret
2. Configure the SCIM bridge (through the `op-scim-config.yaml`) file
3. Deploy the service
4. Set up DNS entries for LetsEncrypt

## Structure

- `op-scim-deployment.yaml`: The SCIM Bridge deployment.
- `op-scim-service.yaml`: Public load balancer for the SCIM Bridge server.
- `op-scim-config.yaml`: Configuration for the SCIM Bridge server. You’ll be modifying this file during the deployment.
- `redis-deployment.yaml`:  [(optional*)](#external-redis-server) A redis server deployment.
- `redis-service.yaml`:  [(optional*)](#external-redis-server) Kubernetes service for the redis deployment.


## Preparing

Please ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.

### Create the `scimsession` Kubernetes secret

The following requires that you’ve completed the initial setup of Provisioning in your 1Password Account. [See here](https://support.1password.com/scim/#step-1-prepare-your-1password-account) for more details.

Once complete, you must create a Kubernetes secret containing the `scimsession` file. Using `kubectl`, we can read the `scimsession` file and create the Kubernetes secret in one command:

```bash
kubectl create secret generic scimsession --from-file=/path/to/scimsession
```


### Configuring the SCIM bridge

You'll need to edit the `op-scim-config.yaml` file and change the variable `OP_LETSENCRYPT_DOMAIN` to the domain you've decided on for your SCIM Bridge. This allows LetsEncrypt to issue your deployment an SSL certificate necessary for encrypted traffic.


## Deploy to the Kubernetes cluster

Run the following `kubectl` command to complete your deployment. It will deploy the both the `redis` server and the `op-scim` app.

```bash
kubectl apply -f .
```


## Configure the DNS entries

The Kubernetes deployment creates a public load balancer in your environment pointing to the SCIM Bridge.

To get its public IP address:

```bash
kubectl describe service/op-scim
```

It can take some time before the public address becomes available.

At this stage, you can finish configuring your DNS entry as outlined in [PREPARATION.md](/PREPARATION.md).


## Test the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account.

You can do this with `curl`, as an example:

```sh
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM Bridge.


## Advanced deployments

The following are helpful tips in case you wish to perform an advanced deployment.

### External load balancer

In `op-scim-config.yaml`, you can set the `OP_LETSENCRYPT_DOMAIN` variable to blank, which will have the SCIM Bridge serve on port 3002. You can then map your pre-existing webserver (Apache, NGINX, etc). You will no longer be issued a certificate by LetsEncrypt.

### External redis server

If you are using an existing redis instance that's not running on `redis:6379`, you can change the `OP_REDIS_HOST` and `OP_REDIS_PORT` variables in `op-scim-config.yaml`.

You would then omit the the `redis-*.yaml` files when deploying to your Kubernetes cluster.
