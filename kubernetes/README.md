# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Passwrd SCIM bridge on Kubernetes running on Google Cloud Platform, but the basic principles can be applied to any Kubernetes cluster.

If deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

## Create your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your IdP. You must create a DNS record that points to your Kubernetes load balancer. This is a chicken and egg problem, as we need the load balancer before we can create the record. Please follow all of the steps until the load balancer has been created, then create your DNS record, but _do not attempt to perform a provisioning sync before the DNS records have been propogated_. The record must exist and the SCIM Bridge server must be running in order for LetsEncrypt to issue a certificate.

## Deploy redis

Use the `redis-deployment.yaml` and `redis-service.yaml` files with kubectl to deploy redis. If you have an existing redis instance, skip this step.

Example:
```
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

This will deploy a single redis instance listening on Kubernetes internal DNS `redis:6379`, which the SCIM Bridge will use for caching during operation. A redis instance is required when using the SCIM Bridge.

## Prepare your 1Password Account

Log in to your 1Password account [using this link](https://my.1password.com/scim/setup).  It will take you to a hidden setup page for the SCIM bridge.

Follow the on-screen instructions which will guide you through the following steps:

* Create a Provision Managers group
* Create and confirm a Provision Manager user

You can then download the `scimsession` file and save your bearer token.  The `scimsession` file contains the credentials for the new Provision Manager user.  This user will creates, confirms, and suspends users, and creates and manages access to groups.  You should use an email address that is unique and not that of another user.

The bearer token and scimsession file combined can be used to sign in to your Provision Manager account. You’ll need to share the bearer token with your identity provider, but it’s important to **never share it with anyone else**. And never share your scimsession file with **anyone at all**.

## Create your `scimsession` Kubernetes secret

Next, we must create a Kubernetes secret containing the scimsession file. Using kubectl, we can read the scimsession file and create the secret in one command:
```
kubectl create secret generic scimsession --from-file=./scimsession
```
Make sure to pass the filepath of the scimsession file that you downloaded.  The above command will look for the file in  this folder (the `/kubernetes/` folder) of the repository.

## Deploy the SCIM bridge

Using the `op-scim-deployment.yaml` and `op-scim-service.yaml` files, deploy the 1Password SCIM bridge to your Kubernetes cluster.

NOTE: In order to obtain an SSL/TLS certificate for your SCIM Bridge instance, you must include a domain name in the `containers.args` field in the `op-scim-deployment.yaml` file. This will only succeed if a DNS record exists that points to your GCP load balancer. Please read the section about DNS records at the beginning of this example.

NOTE: If you are using an existing redis instance that is not running on `redis:6379`, add the `--redis-host=[host]` and `--redis-port=[port]` flags to `containers.args` in the deployment yaml file.

Example:
```
kubectl apply -f op-scim-deployment.yaml
kubectl apply -f op-scim-service.yaml
```

These files configure the 1Password SCIM Bridge to connect to the redis instance indicated by the args, and it deploys a GCP load balancer to handle traffic on ports 80 and 443. Traffic on :80 is needed to perform the LetsEncrypt certificate challenges, after which all SCIM traffic will be served on :443

NOTE: Port 80 on the load balancer is forwarded to :8080 on the SCIM Bridge, and port 443 is forwarded to :8443.

At this point you should create your DNS record using the external IP address of the load balancer and wait for it to propogate.

Once the record is propogated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account.  You can do this with `curl` as follows:

```
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

Alternatively, visit the domain you configured earlier.  You'll see a 1Password SCIM Bridge Status page which can be used to verify your OAuth bearer token.

You can now continue with the administration guide to configure your IdP to enable provisioning with your SCIM Bridge.
