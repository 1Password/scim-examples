# Deploying the 1Password SCIM Bridge on Kubernetes

This example explains how to deploy the 1Passwrd SCIM bridge on Kubernetes running on Google Cloud Platform, but the basic principles can be applied to any Kubernetes cluster.

If deploying to the Azure Kubernetes Service, you can refer to our [detailed deployment guide instead](https://support.1password.com/cs/scim-deploy-azure/).

## Start creating your DNS record

The 1Password SCIM bridge requires SSL/TLS in order to communicate with your Identity Provider. To do that, you must create a DNS record that points to your Kubernetes load balancer. 

This is a chicken and egg problem, as we need the load balancer online with an IP address before we can create the DNS record. 

Please follow all of the steps until the load balancer has been created, and at the very end, you will finish setting up the DNS record.

For now, you'll want to choose what domain name you'll want to use for this SCIM bridge. As an example: `op-scim.example.com`.

IMPORTANT: _Do not attempt to perform a provisioning sync before the DNS records have been propagated_. The record must exist and the SCIM Bridge server must be running in order for LetsEncrypt to issue a certificate.


## Prepare your 1Password Account

Log in to your 1Password account [using this link](https://start.1password.com/settings/provisioning/setup). It will take you to the setup page for the SCIM bridge. Follow the instructions there.

*IMPORTANT*: When the setup asks you for an email address for the new Provision Manager user it creates for you automatically, use a dedicated email address (for example: `op-provision-manager@example.com`) to handle this account. It is _not advised_ to use any personal email address!

Once complete, you'll be provided with two separate secrets:

* a `scimsession` file 
* a bearer token

The `scimsession` file contains the credentials for the new Provision Manager user the setup process automatically created for you. This user will create, confirm, and suspend users, and create and manage access to groups.  

*IMPORTANT*: Do not share these secrets! The bearer token must be provided to your Identity Provider, but beyond that it should be kept safe and not shared with anyone. Especially important is the `scimsession` file - do not share that with ANYONE, except the SCIM bridge.

To reiterate: you'll need to share the bearer token with your Identity Provider, but it's important to **never share it with anyone else**. And never share your `scimsession` file with **anyone at all**.

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

A redis instance is required when using the SCIM Bridge, whether you use the option provided her to deploy one, or have configured one yourself independently.

If you're not self-hosting your own redis server, you can set one up during this process. Otherwise, if you specified a custom redis server in the previous steps, you can skip this section.

Use the `redis-deployment.yaml` and `redis-service.yaml` files with `kubectl` to deploy redis. If you have an existing redis instance, skip this step.

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

It's important that you use the IP address of the container that runs the load balancer. The load balancer is what handles traffic for ports 80 and 443 for the SCIM bridge. Here are the mappings:

```
Load Balancer: 80 -> SCIM Bridge: 8080
Load Balancer: 443 -> SCIM Bridge: 8443
```

Within your DNS provider, create the DNS record for the domain you decided on in _Start creating your DNS record_. You should give it a few minutes to propagate. This can take anywhere from 5 minutes to an hour depending on what DNS provider you're using for the domain.

You may or may not need to reboot the containers you've deployed to ensure the LetsEncrypt challege service finishes correctly, but you should see if it automatically completes on its own before doing so.


## Test the instance

Once the DNS record has propagated, you can test your instance by requesting `https://[your-domain]/scim/Users`, with the header `Authorization: Bearer [bearer token]` which should return a list of the users in your 1Password account. 

You can do this with `curl`, as an example:
```
curl --header "Authorization: Bearer <bearertoken>" https://<domain>/scim/Users
```

Alternatively, you can visit the domain via any web browser. You'll see a 1Password SCIM Bridge Status page which can be used to verify your OAuth bearer token. It is safe to put the bearer token in this page.

You can now continue with the administration guide to configure your Identity Provider to enable provisioning with your SCIM Bridge.
