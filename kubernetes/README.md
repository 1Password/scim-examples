# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Password SCIM bridge on Kubernetes running on Google Cloud Platform, but the basic principles can be applied to any Kubernetes cluster.

If deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

## Preparing

Please ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.

## Create your `scimsession` Kubernetes secret

Next, we must create a Kubernetes secret containing the scimsession file. Using `kubectl`, we can read the scimsession file and create the secret in one command:

```
kubectl create secret generic scimsession --from-file=./scimsession
```

Make sure to pass the filepath of the scimsession file that you downloaded.  The above command will look for the file in  this folder (the `/kubernetes/` folder) of the repository.


## Configuring the SCIM bridge

You'll want to edit the `op-scim-deployment.yaml` file and change the variable `{YOUR-DOMAIN-HERE}` to the domain you've decided on. This allows LetsEncrypt to issue your deployment an SSL certificate necessary for encrypted traffic. 

To finish setting up DNS, need to have the IP address of the load balancer container. Continue with deployment, and then finish configuring the DNS near the end.


## Deploy redis

A redis instance is required when using the SCIM Bridge, whether you use the option provided her to deploy one, or have configured one yourself independently. (See [Advanced setup](#Advanced-setup))

Use the `redis-deployment.yaml` and `redis-service.yaml` files with `kubectl` to deploy redis.

Example:

```
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

This will deploy a single redis instance listening on Kubernetes internal DNS `redis:6379`, which the SCIM Bridge will use for caching during operation. 


## Deploy the SCIM bridge 

Using the `op-scim-deployment.yaml` and `op-scim-service.yaml` files, deploy the 1Password SCIM bridge to your Kubernetes cluster.

These files deploy the 1Password `op-scim` service, and deploys a load balancer to handle traffic on ports 80 and 443. Traffic on :80 is needed to perform the LetsEncrypt certificate challenges, after which all SCIM traffic will be served on :443.

Ensure that your options in `op-scim-deployment.yaml` are set, and deploy using the following:

```
kubectl apply -f op-scim-deployment.yaml
kubectl apply -f op-scim-service.yaml
```


## Configuring DNS

At this stage, you can finish configuring your DNS entry as outlined in [PREPATATION.md](/PREPARATION.md). Please ensure you're using the IP address of the op-scim service you've deployed, which should have been automatically assigned.


## Test the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account. 

You can do this with `curl`, as an example:
```
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

Alternatively, you can visit the domain in any web browser. You'll see a 1Password SCIM Bridge Status page which can be used to verify your OAuth bearer token. This page is being served by your SCIM Bridge using a secured TLS connection established using your LetsEncrypt domain certificate.

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM Bridge.

## Advanced setup (optional)

If you have infrastructure already in place, such as a web server, a redis server, and/or a pre-existing SSL certificate, you can integrate the op-scim service with them instead of using the load balancer and redis container deployments.

### Web server with SSL certificate

In `op-scim-deployment.yaml`, you can remove the option `--letsencrypt-domain`. This will have the op-scim service serve on port 3002. You can then map your pre-existing webserver (Apache, NGINX, etc). You will no longer be issued a certificate by LetsEncrypt.

### Redis server

If you are using an existing redis instance that's not running on `redis:6379`, add the `--redis-host=[host]` and `--redis-port=[port]` flags to `containers.args` in that same `op-scim-deployment.yaml` file.
