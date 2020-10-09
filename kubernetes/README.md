# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Password SCIM bridge on a Kubernetes cluster. It assumes your kubernetes cluster supports "load-balancer" services.

If you are deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

The deployment process consists of these steps:

1. Create the scimsession Kubernetes secret
2. Configure the SCIM bridge (through the `op-scim-deployment.yaml`) file
3. Deploy the manifests
4. Set up DNS entries for let's encrypt

## Structure

- `op-scim-deployment.yaml`: The SCIM bridge deployment. See the command line options configuratble
- `op-scim-service.yaml`: The public load-balancer for the service 
- `redis-deployment.yaml`:  [(optional*)](#optional-redis) A redis server deployment. 
- `redis-service.yaml`:  [(optional*)](#optional-redis) Kubernetes service for the redis deployment. Referenced by `op-scim` app.

_<a name="optional-redis"></a>* A redis instance is required when using the SCIM Bridge. You can use your own already existing redis instances. This is configurable through the `--redis-host` and `--redis-port` command line flags._

## Preparing

Please ensure you've read through the [PREPARATION.md](/PREPARATION.md) document before beginning deployment.

### Create the `scimsession` Kubernetes secret

Next, we must create a Kubernetes secret containing the scimsession file. Using `kubectl`, we can read the scimsession file and create the secret in one command:

```
kubectl create secret generic scimsession --from-file=./scimsession
```

Make sure to pass the filepath of the scimsession file that you downloaded.  The above command will look for the file in this folder (the `/kubernetes/` folder) of the repository.


### Configuring the SCIM bridge

You'll want to edit the `op-scim-deployment.yaml` file and change the variable `{YOUR-DOMAIN-HERE}` to the domain you've decided on. This allows LetsEncrypt to issue your deployment an SSL certificate necessary for encrypted traffic. 


## Deploy to the kubernetes cluster

```sh
kubectl apply -f .
```


## Configure the DNS entries

The Kubernetes deployment creates a public load balancer in your environment pointing to the SCIM Bridge. To get its address use: `kubectl describe service/op-scim`. It can take some time before the public address becomes available.

At this stage, you can finish configuring your DNS entry as outlined in [PREPATATION.md](/PREPARATION.md). 


## Test the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account. 

You can do this with `curl`, as an example:

```sh
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

Alternatively, you can visit the domain in any web browser. You'll see a 1Password SCIM Bridge Status page which can be used to verify your OAuth bearer token. This page is being served by your SCIM Bridge using a secured TLS connection established using your LetsEncrypt domain certificate.

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM Bridge.