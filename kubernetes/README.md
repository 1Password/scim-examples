# Deploy 1Password SCIM Bridge on Kubernetes

_Learn how to deploy 1Password SCIM Bridge on a Kubernetes cluster._

> **Note**
>
> If you use Azure Kubernetes Service, learn how to [deploy the SCIM bridge there](https://support.1password.com/scim-deploy-azure/).

**Table of contents:**

- [Before you begin](#before-you-begin)
- [Step 1: Create the `scimsession` Kubenetes Secret](#step-1-create-the-scimsession-kubernetes-secret)
- [Step 2: Deploy 1Password SCIM Bridge to the Kubernetes cluster](#step-2-deploy-1password-scim-bridge-to-the-kubernetes-cluster)
- [Step 3: Create a DNS record](#step-3-create-a-dns-record)
- [Step 4: Configure Let's Encrypt](#step-4-configure-lets-encrypt)
- [Step 5: Test the SCIM bridge](#step-5-test-your-scim-bridge)
- [Step 6: Connect your identity provider](#step-6-connect-your-identity-provider)
- [Update your SCIM Bridge](#update-your-scim-bridge)
- [Appendix: Resource recommendations](#appendix-resource-recommendations)
- [Appendix: Customize your deployment](#appendix-customize-your-deployment)

## Before you begin

Before you begin, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

Clone this repository and switch to this working directory:

```sh
git clone https://github.com/1Password/scim-examples.git
cd ./scim-examples/kubernetes
```

### In this folder

- [`op-scim-config.yaml`](./op-scim-config.yaml): Configuration for the SCIM bridge deployment.
- [`op-scim-deployment.yaml`](./op-scim-deployment.yaml): The deployment manifest for the SCIM bridge container.
- [`op-scim-service.yaml`](./op-scim-service.yaml): Public load balancer for SCIM bridge to connect with your identity provider.
- [`redis-config.yaml`](./redis-config.yaml): Configuration for the Redis cache.
- [`redis-deployment.yaml`](./redis-deployment.yaml): The deployment manifest for a Redis cache in the cluster.
- [`redis-service.yaml`](./op-scim-service.yaml): Kubernetes Service for the Redis cache to enable connectivity inside the cluster.
- [`google-workspace/workspace-settings.json`](./google-workspace/workspace-settings.json): a settings file template for customers integrating with Google Workspace.

## Step 1: Create the `scimsession` Kubernetes Secret

After you [prepare your 1Password account](/PREPARATION.md#prepare-your-1password-account):

1. Save the `scimsession` credentials file from your 1Password account to the working directory (`scim-examples/kubernetes`).
2. Make sure the file is named `scimsession`.
3. Create a [Kubernetes Secret](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret) from this file:

   ```sh
   kubectl create secret generic scimsession --from-file=scimsession=./scimsession
   ```

### If Google Workspace is your identity provider

> **Warning**
>
> The following steps only apply if you use Google Workspace as your identity provider. If you use another identity
> provider, [continue to step 2](#step-2-deploy-1password-scim-bridge-to-the-kubernetes-cluster).

1. Follow the steps to [create a Google service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client).
2. Save the credentials file to the `google-workspace` subfolder in this directory.
3. Make sure the key file is named `workspace-credentials.json`.
4. Edit the Workpsace settings file template located at [`./google-workspace/workspace-settings.json`](./google-workspace/workspace-settings.json) and fill in correct values for:
   - **Actor**: the email address of the administrator in Google Workspace that the service account is acting on behalf of.
   - **Bridge Address**: the URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is most often a subdomain of your choosing on a domain you own. For example: `https://scim.example.com`.
5. Return to the working directory for all following steps (`scim-examples/kubernetes`).
6. Create Kubernetes Secrets from these files:

   ```sh
   kubectl create secret generic workspace-credentials \
       --from-file=workspace-credentials.json=./google-workspace/workspace-credentials.json
   kubectl create secret generic workspace-settings \
       --from-file=workspace-settings.json=./google-workspace/workspace-settings.json
   ```

## Step 2: Deploy 1Password SCIM Bridge to the Kubernetes cluster

Run the following command to deploy 1Password SCIM Bridge:

```sh
kubectl apply --filename=./
```

## Step 3: Create a DNS record

The [`op-scim-bridge` Service](./op-scim-service.yaml) creates a public load balancer attached to your cluster, which forwards TLS traffic to SCIM bridge.

1. Run the following command:

   ```sh
   kubectl get service
   ```

2. Copy the address listed under the `External IP` column for the `op-scim-bridge` Service from the output.
   > **Note**
   >
   > It can take a few minutes before the public address becomes available. Run the command again if doesn't appear in the output.
3. Create a public DNS record pointing to this address.

## Step 4: Configure Let's Encrypt

After the DNS record has propagated, set the `OP_TLS_DOMAIN` environment variable to enable the CertificateManager component.

_Example command:_

```sh
kubectl set env deploy/op-scim-bridge OP_TLS_DOMAIN=scim.example.com
```

Replace `scim.example.com` with the fully qualified domain name of the DNS record before running this command. Your SCIM bridge will restart, request a TLS certificate from Let's Encrypt, and automatically renew the certificate on your behalf.

## Step 5: Test your SCIM bridge

You can test the connection to your SCIM bridge and view status and logs in a web browser at the URL based on its fully qualified domain name (for example `https://scim.example.com/`). Sign in to your SCIM bridge using the bearer token associated with the `scimsession` credentials stored as a Secret on your cluster.

You can also test your SCIM bridge by sending an authenticated SCIM API request.

_Example command:_

```sh
curl --header "Authorization: Bearer mF_9.B5f-4.1JqM" https://scim.example.com/Users
```

Copy the example command to a text editor. Replace `mF_9.B5f-4.1JqM` with your bearer token and `scim.example.com` with its fully qualified domain name.

<details>
<summary>Example JSON response</summary>

> ```json
> {
>   "Resources": [
>     {
>       "active": true,
>       "displayName": "Eggs Ample",
>       "emails": [
>         {
>           "primary": true,
>           "type": "",
>           "value": "eggs.ample@example.com"
>         }
>       ],
>       "externalId": "",
>       "groups": [
>         {
>           "value": "f7eqriu7ht27mq5zmm63gf2dhq",
>           "ref": "https://scim.example.com/Groups/f7eqriu7ht27mq5zmm63gf2dhq"
>         }
>       ],
>       "id": "FECPUMYBHZB2PB6K4WKM4Q2HAU",
>       "meta": {
>         "created": "",
>         "lastModified": "",
>         "location": "",
>         "resourceType": "User",
>         "version": ""
>       },
>       "name": {
>         "familyName": "Ample",
>         "formatted": "Eggs Ample",
>         "givenName": "Eggs",
>         "honorificPrefix": "",
>         "honorificSuffix": "",
>         "middleName": ""
>       },
>       "schemas": [
>         "urn:ietf:params:scim:schemas:core:2.0:User"
>       ],
>       "userName": "eggs.ample@example.com"
>     },
>     ...
>   ]
> }
> ```

</details>

## Step 6: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM bridge

To update SCIM bridge, connect to your Kubernetes cluster and run the following command:

```sh
kubectl set image deploy/op-scim-bridge op-scim-bridge=1password/scim:v2.8.4
```

> **Note**
>
> You can find details about the changes in each release of 1Password SCIM Bridge on our [Release
> Notes](https://app-updates.agilebits.com/product_history/SCIM) page. The most recent version should be pinned in the
> [`op-scim-deployment.yaml`](./op-scim-deployment.yaml) file (and in the command above in this file) in the main
> branch of this repository.

Your SCIM bridge should automatically reboot using the specified version, typically in a few moments.

## Rotate credentials

If you regenenerate credentials for your SCIM bridge:

1. Download the new `scimsession` file from your 1Password account.
2. Delete the `scimsession` Secret on your cluster and recreate it from the new file:

   ```sh
   kubectl delete secret scimsession
   kubectl create secret generic scimsession --from-file=scimsession=./scimsession
   ```

   Kubernetes automatically updates the credentials file mounted in the Pod with the new Secret value.

3. Test your SCIM bridge using the new bearer token associated with the regenerated `scimsession` file.
4. Update your identity provider configuration with the new bearer token.

## Appendix: Resource recommendations

The default resource recommendations for the SCIM bridge and Redis deployments are acceptable in most scenarios, but they may fall short in high-volume deployments where a large number of users and/or groups are being managed. We strongly recommend increasing the resources for both the SCIM bridge deployment.

Once all users and groups have been provisioned, it is safe to lower these resources back to their defaults for everyday use of the SCIM bridge.

| Expected Provisioned Users | Resources                   |
| -------------------------- | --------------------------- |
| 1-1000                     | Default                     |
| 1000-5000                  | High Volume Deployment      |
| 5000+                      | Very High Volume Deployment |

Our current default resource requirements (defined in [op-scim-deployment](https://github.com/1Password/scim-examples/blob/master/kubernetes/op-scim-deployment.yaml#L29) and [redis-deployment.yaml](https://github.com/1Password/scim-examples/blob/master/kubernetes/redis-deployment.yaml#L21)) are:

<details>
  <summary>Default</summary>

```yaml
requests:
  cpu: 125m
  memory: 256M

limits:
  cpu: 250m
  memory: 512M
```

</details>

Note that these are the recommended `requests` and `limits` values for both the SCIM bridge and Redis containers. These values can be scaled down again to the default values after the initial large provisioning event.

<details>
  <summary>High Volume Deployment</summary>

```yaml
requests:
  cpu: 500m
  memory: 512M

limits:
  memory: 1024M
```

</details>

<details>
  <summary>Very High Volume Deployment</summary>

The best practices for Kubernetes resource limits are:

1.  Never set [CPU](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource) limits to avoid Kubernetes CPU throttling and allow for efficient use of available CPU.
2.  Set [Memory](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource) limits same as requests to help avoiding OOM kills.

This works well in the deployment scenario where the 1Password SCIM bridge is the only pod in the cluster, so that it has a priority of service and can consume all the resources in the cluster without affecting the performance of other pods.

If you are deploying the SCIM bridge to a cluster **without** other production services, we recommend setting the following CPU and memory resources:

> **Note**
>
> We recommend to not set CPU limits when you expect higher performance. However, you can set CPU limits to manage resources if needed. This can be modified in your deployment based on our generic example, and its expected to work in most circumstances.

```yaml
requests:
  cpu: 1000m
  memory: 1024M

limits:
  memory: 1024M
```

</details>

Configuring these values can be done with Kubernetes commands. You can get the names of the deployments with `kubectl get deployments`.

```sh
# scale down deployment
kubectl scale --replicas=0 deployment/op-scim-bridge

# scale down redis deployment
kubectl scale --replicas=0 deployment/op-scim-bridge-redis-master

# update op-scim-redis resources
kubectl set resources deployment op-scim-bridge-redis-master -c=redis --requests=cpu=250m,memory=512M --limits=cpu=500m,memory=1024M

# update op-scim-bridge resources
kubectl set resources deployment op-scim-bridge -c=op-scim-bridge --requests=cpu=500m,memory=512M --limits=cpu=1000m,memory=1024M

# scale up deployment
kubectl scale --replicas=1 deployment/op-scim-bridge-redis-master

# scale up deployment
kubectl scale --replicas=1 deployment/op-scim-bridge
```

Please reach out to our [support team](https://support.1password.com/contact/) if you need help with the configuration or to tweak the values for your deployment.

## Appendix: Customize your deployment

You can customize your 1Password SCIM Bridge deployment using some of the methods below.

### Self-managed TLS

There are two ways to use a self-managed TLS certificate, which disables Let's Encrypt functionality.

#### Load balancer

You can terminate TLS traffic on a public-facing load balancer or reverse proxy, then redirect HTTP traffic to SCIM bridge within your private network. Skip the step to configure Let's Encrypt, or revert to the default state by setting `OP_TLS_DOMAIN` to `""`:

```sh
kubectl set env deploy/op-scim-bridge OP_TLS_DOMAIN=""
```

Modify [`op-scim-service.yaml`](./op-scim-service.yaml) to use the alternate `http` port for the Service as noted within the manifest. Traffic from your TLS endpoint should be directed to this port (80, by default). If SCIM bridge has already been deployed, apply the amended Service manifest:

```sh
kubectl apply --filename=./op-scim-service.yaml
```

In this configuration, 1Password SCIM Bridge will listen for unencrypted traffic on the `http` port of the Pod.

#### Use your own certificate

Alternatively, you can create a TLS Secret containing your key and certificate files, which can then be used by your SCIM bridge. This will also disable Let's Encrypt functionality.

Assuming these files exist in the working directory, create the Secret and set the `OP_TLS_CERT_FILE` and `OP_TLS_KEY_FILE` variables to redeploy SCIM bridge using your certificate:

```sh
kubectl create secret tls op-scim-tls --cert=./certificate.pem --key=./key.pem
kubectl set env deploy op-scim-bridge \
  OP_TLS_CERT_FILE="/secrets/tls.crt" \
  OP_TLS_KEY_FILE="/secrets/tls.key"
```

> **Note**
>
> If your certificate and key files are located elsewhere or have different names, replace `./certificate.pem` and `./key.pem` with the paths to these files, i.e.:
>
> ```sh
> kubectl create secret tls op-scim-tls --cert=path/to/cert/file --key=path/to/key/file
> ```

### External Redis

If you prefer to use an external Redis cache, omit the the `redis-*.yaml` files when deploying to your Kubernetes cluster. Replace the value of the `OP_REDIS_URL` environment variable in [`op-scim-config.yaml`](./op-scim-config.yaml) with a Redis connection URI for your Redis server.

#### If you already deployd your SCIM bridge

You can set `OP_REDIS_URL` directly to reboot SCIM bridge and connect to the specified Redis server:

_Example command:_

```sh
kubectl set env deploy/op-scim-bridge OP_REDIS_URL="redis://LJenkins:p%40ssw0rd@redis-16379.example.com:16379/0"
```

Replace `redis://LJenkins:p%40ssw0rd@redis-16379.example.com:16379/0` with a Redis connection URI for your Redis server before running the command.

Delete the cluster resources for Redis:

```sh
kubectl delete \
  --filename=redis-config.yaml \
  --filename=redis-deployment.yaml \
  --filename=redis-service.yaml
```

### Colorful logs

Set `OP_PRETTY_LOGS` to `1` to colorize container logs.

```sh
kubectl set env deploy/op-scim-bridge OP_PRETTY_LOGS=1
```

### JSON logs

By default, container logs are output in a human-readable format. Set `OP_JSON_LOGS` to `1` for newline-delimited JSON logs.

```sh
kubectl set env deploy/op-scim-bridge OP_JSON_LOGS=1
```

This can be useful for capturing structured logs.

### Debug logs

Set `OP_DEBUG` to `1` to enable debug level logging:

```sh
kubectl set env deploy/op-scim-bridge OP_DEBUG=1
```

This may be useful for troubleshooting, or when contacting 1Password Support.

### Trace logs

Set `OP_TRACE` to `1` to enable trace level debug output in the logs:

```sh
kubectl set env deploy/op-scim-bridge OP_TRACE=1
```

This may be useful for troubleshooting Let’s Encrypt integration issues.

### PingServer component

On some Kubernetes clusters, health checks can fail for the SCIM bridge before the bridge is able to obtain a Let’s Encrypt certificate. Set `OP_PING_SERVER` to `1` to enable a `/ping` endpoint available on port 80 to use for health checks:

```sh
kubectl set env deploy/op-scim-bridge OP_PING_SERVER=1
```

No other endpoints (such as `/scim`) are exposed through this port.
