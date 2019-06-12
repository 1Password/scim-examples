# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Passwrd SCIM bridge on Kubernetes running on Google Cloud Platform, but the basic principles can be applied to any Kubernetes cluster.

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

## Create your `scimsession` Kubernetes secret

Firstly, use the [scim-setup.sh](https://github.com/1Password/scim-examples/tree/master/scim-setup.sh) script on your local machine to set up your account and generate a `scimsession` file. This script uses a Docker container to run the `op-scim setup` command and writes the scimsession file back to your local machine using a mounted volume. Your bearer token will be printed to the console.

The scimsession file is equivalent to your account key and master password when combined with the bearer token, therefore they should never be stored in the same place.

Example:
```
scim-setup.sh
[account sign-in]
Bearer token: jafewnqrrupcnoiqj0829fe209fnsoudbf02efsdo
```
This script is an interactive setup of your 1Password account. It is reccomended to save the bearer token in 1Password within an account _other than the provision manager's_.

Next, we must create a Kubernetes secret containing the scimsession file. Using kubectl, we can read the scimsession file and create the secret in one command:
```
kubectl create secret generic scimsession --from-file=./scimsession
```
Make sure to pass the filepath of the scimsession file that was created by the `scim-setup.sh` script.

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

Once the record is propogated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account.

You can now continue with the administration guide to configure your IdP to enable provisioning with your SCIM Bridge.
