# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Passwrd SCIM bridge on Kubernetes running on Google Cloud Platform, but the basic principles can be applied to any Kubernetes cluster.

If deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

## Before beginning

There are a few pieces of information you'll want to decide on before beginning the setup process:

* Your SCIM bridge domain name. (example: `op-scim-bridge.example.com`)
* An email to use for the automatically-created Provision Manager user. (example: `op-scim@example.com`)

In addition, there are a few things to keep in mind before you begin deployment.

* Do not create the Provision Manager user manually. Let the setup process create the Provision Manager user for you **automatically.**
* When the Provisioning setup asks you for an email address for the new Provision Manager user it creates for you automatically, use a dedicated email address (for example: `op-provision-manager@example.com`) to handle this account. It is _not advised_ to use any personal email address. At no point should you need to log into this new Provision Manager account manually.
* Do not attempt to perform a provisioning sync the setup has been completed. 
* **IMPORTANT:** You will be provided with two separate secrets: a `scimsession` file and a Bearer token. **Do not share these secrets!** The bearer token must be provided to your Identity Provider, but beyond that it should be kept safe and **not shared with anyone else.** The `scimsession` file should only be shared with the SCIM bridge itself.


## Start creating your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your Identity Provider. To do that, you must create a DNS record that points to your Kubernetes load balancer. 

This is a chicken and egg problem, as we need the load balancer online with an IP address before we can create the DNS record. 

Please follow all of the steps until the load balancer has been created, and at the very end, you will finish setting up the DNS record with the domain you decided on in [Before beginning](#Before-beginning).


## Prepare your 1Password Account

Log in to your 1Password account [using this link](https://start.1password.com/settings/provisioning/setup). It will take you to the setup page for the SCIM bridge. Follow the instructions there.

During this process, the setup will guide you through the following process:

* Automatically creating a Provision Managers group
* Automatically creating a Provision Manager user
* Generating your SCIM bridge credentials

The SCIM bridge credentials are split into two equally-important parts:

* a `scimsession` file 
* a bearer token

The `scimsession` file contains the credentials for the new Provision Manager user the setup process automatically created for you. This user will create, confirm, and suspend users, and create and manage access to groups.

**IMPORTANT:** As stated before, please keep these secrets in a secure location, and don't share them with anyone unless absolutely necessary.


## Create your `scimsession` Kubernetes secret

Next, we must create a Kubernetes secret containing the scimsession file. Using `kubectl`, we can read the scimsession file and create the secret in one command:

```
kubectl create secret generic scimsession --from-file=./scimsession
```

Make sure to pass the filepath of the scimsession file that you downloaded.  The above command will look for the file in  this folder (the `/kubernetes/` folder) of the repository.


## Configuring the SCIM bridge

You'll want to edit the `op-scim-deployment.yaml` file and change the variable `{YOUR-DOMAIN-HERE}` you've decided on in _Creating your DNS record_. This allows LetsEncrypt to issue your deployment an SSL certificate necessary for encrypted traffic. As discussed in that section, you'll need to have the IP address of the container, so we'll continue with deployment, and then finish configuring the DNS.

Additionally, if you are using an existing redis instance that's not running on `redis:6379`, add the `--redis-host=[host]` and `--redis-port=[port]` flags to `containers.args` in that same `op-scim-deployment.yaml` file.


## Deploy redis

A redis instance is required when using the SCIM Bridge, whether you use the option provided her to deploy one, or have configured one yourself independently. If you defined a pre-existing redis instance in [Configuring the SCIM bridge)[#Configuring-the-SCIM-bridge], you can skip this section.

Use the `redis-deployment.yaml` and `redis-service.yaml` files with `kubectl` to deploy redis.

Example:

```
kubectl apply -f redis-deployment.yaml
kubectl apply -f redis-service.yaml
```

This will deploy a single redis instance listening on Kubernetes internal DNS `redis:6379`, which the SCIM Bridge will use for caching during operation. 


## Deploy the SCIM bridge 

Using the `op-scim-deployment.yaml` and `op-scim-service.yaml` files, deploy the 1Password SCIM bridge to your Kubernetes cluster.

These files configure the 1Password SCIM Bridge to connect to the redis instance indicated by the args, and it deploys a load balancer to handle traffic on ports 80 and 443. Traffic on :80 is needed to perform the LetsEncrypt certificate challenges, after which all SCIM traffic will be served on :443.

```
kubectl apply -f op-scim-deployment.yaml
kubectl apply -f op-scim-service.yaml
```


## Finish configuring DNS

As mentioned before, you'll need to configure you DNS after the fact, as configuring DNS requires the IP address of the deployed container.

It's important that you use the IP address of the container that runs the load balancer. 

Within your DNS provider, create the DNS record for the domain you decided on in [Start creating your DNS record](#Start-creating-your-DNS-record). You should give it a few minutes to propagate. 


## Test the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account. 

You can do this with `curl`, as an example:
```
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

Alternatively, you can visit the domain in any web browser. You'll see a 1Password SCIM Bridge Status page which can be used to verify your OAuth bearer token. This page is being served by your SCIM Bridge using a secured TLS connection established using your LetsEncrypt domain certificate.

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM Bridge.
