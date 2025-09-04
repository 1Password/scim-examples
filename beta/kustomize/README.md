# Deploy 1Password SCIM Bridge on Kubernetes with Kustomize

_Learn how to deploy 1Password SCIM Bridge on a Kubernetes cluster using Kustomize._

> **Note**
>
> If you use Azure Kubernetes Service, learn how to [deploy the SCIM bridge there](https://support.1password.com/scim-deploy-azure/).

## Before you begin

Before you begin, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

Additionally, as there are various subfolders needed, all paths will be based with a `.`.
This `.` refers to the folder that contains this readme, and will be referred to as the Root Folder. For example, the Let's Encrypt
options are referenced as `./overlays/letsencrypt`.

### In this folder

- [`/base`](./base/): The default deployment that the overlays build on top of to
  deploy your preferred bridge.
- [`/overlays`](./overlays/): The overlays to customize your deployment.
- [`README.md`](./README.md): the document that you are reading. 👋😃

## Step 1: Prepare your `scimsession` file

So that Kustomize can create a secret from your `scimsession` file, place it in the
`./base` directory. The full path should be `./base/scimsession`. Kubernetes
will use this file along with a Kustomize secret generator to create the Kubernetes secret
containing the contents of your `scimsession` file, named as `scimsession`.

## Step 2: Determine which overlays to use

There are currently 3 overlays defined for modifying the deployment of the bridge, in
addition to the deployment overlay. In most standard deployments, the `letsencrypt`
overlay is going to be used. This overlay configures the SCIM bridge to request a
certificate from Let's Encrypt using a domain name defined in the overlay ConfigMap.
If you're bringing your own TLS certificate, the `self-managed-tls` overlay is to be
used instead.

While you will be enabling the Let's Encrypt overlay, there are final changes that will
need to be made after the initial deployment.

If you're using Google Workspace, you'll also need the `workspace` overlay configured
as documented in that overlay's README.

## Step 3 (Optional): Configure the overlays

### Self Managed TLS

If you'd prefer to bring your own certificate for use with CertificateManager instead
of using Let's Encrypt, add your TLS private key and certificate to the folder
`./overlays/self-managed-tls` named `tls.key` and `tls.cert` respectively.

### Google Workspace

Place the credentials file in the `./overlays/workspace` folder. The kustomization overlay
will create this as an additional secret.

Edit the file `workspace-settings.json` and fill in correct values for:

- **Actor**: The email address of the administrator in Google Workspace that the service account is acting on behalf of.
- **Bridge Address**: The URL you will use for your SCIM bridge (not your 1Password account sign-in address). This is most often a subdomain of your choosing on a domain you own. If you're using the Let's Encrypt overlay, this would be the value of `OP_TLS_DOMAIN` configured in `patch-configmap.yaml`. It's possible `OP_TLS_DOMAIN` has not been configured yet. If so, use the intended value of `OP_TLS_DOMAIN` as the value for the Bridge Address.

## Step 4: Prepare the deployment

To configure the deployment for use, edit the file
`./overlays/deployment/kustomization.yaml` and make changes as appropriate. For
example: if you're going to be using a self-managed TLS certificate, then comment out
the `letsencrypt` overlay and instead uncomment the `self-managed-tls` overlay.

Next, run the following command while in the Root Folder to deploy your bridge:

```bash
kubectl apply -k ./overlays/deployment
```

## Step 5: Final configuration

If using Let's Encrypt, it's necessary to create the deployment _first_, and then
configure the domain that 1Password SCIM Bridge should request a certificate for.

After your initial deploy, run `kubectl get service`. The output will show three services,
one with the type of LoadBalancer. If an external IP address is pending for the
LoadBalancer, run the command again until an external IP address is shown. This IP
address should be configured as the target IP address of the public DNS record for your SCIM bridge, as mentioned in
the Preparation document. As an example, it could be `scim.example.com`, where
`example.com` is a domain you control.

After creating the DNS record with your DNS provider, edit the file
`patch-configmap.yaml` in the Let's Encrypt overlay folder. Replace the value
`scim.example.com` with the DNS record created. Save this file.

From the Root Folder, redeploy the bridge using the command listed in step 4. The
SCIM bridge will restart using this new deployment, and configure the Let's Encrypt
integration to issue and use a certificate.

## Step 6: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM bridge

👍 Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://app-updates.agilebits.com/product_history/SCIM).

To update the SCIM bridge, connect to your Kubernetes cluster and run the following command, replacing v2.9.13 with the latest version:

```bash
kubectl set image deploy/op-scim-bridge op-scim-bridge=1password/scim:v2.9.13 -n=op-scim
```

The update should take 2-3 minutes for Kubernetes to complete.

## Appendix:

### Resource recommendations

The default resource recommendations for the SCIM bridge and Redis deployments are acceptable in most scenarios, but they may fall short in high-volume deployments where a large number of users and/or groups are being managed. We strongly recommend increasing the resources for both the SCIM bridge and Redis deployments.

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
  cpu: 1000m
  memory: 1024M
```

</details>

<details>
  <summary>Very High Volume Deployment</summary>

```yaml
requests:
  cpu: 1000m
  memory: 1024M

limits:
  cpu: 2000m
  memory: 2048M
```

</details>

Configuring these values can be done with Kubernetes commands. You can get the names of the deployments with `kubectl get deployments`.

```bash
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
