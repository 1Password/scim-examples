# Deploy 1Password SCIM Bridge on Kubernetes

> **Note**
>
> If you use Azure Kubernetes Service, learn how to [deploy the SCIM bridge there](https://support.1password.com/cs/scim-deploy-azure-kubernetes/).

_Learn how to deploy 1Password SCIM Bridge on a Kubernetes cluster._


## Before you begin

Before you begin, complete the necessary [preparation steps to deploy 1Password SCIM Bridge](/PREPARATION.md). Then clone this repository and switch to this working directory:

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
- [`redis-service.yaml`](./redis-service.yaml): Kubernetes Service for the Redis cache to enable connectivity inside the cluster.
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
4. Edit the Workspace settings file template located at [`./google-workspace/workspace-settings.json`](./google-workspace/workspace-settings.json) and fill in correct values for:
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

Use your SCIM bridge URL to test the connection and view status information. For example:

```sh
curl --silent --show-error --request GET --header "Accept: application/json" \
  --header "Authorization: Bearer mF_9.B5f-4.1JqM" \
  https://scim.example.com/health
```

Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://scim.example.com` with your SCIM bridge URL.

<details>
<summary>Example JSON response:</summary>

```json
{
  "build": "209131",
  "version": "2.9.13",
  "reports": [
    {
      "source": "ConfirmationWatcher",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "RedisCache",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    },
    {
      "source": "SCIMServer",
      "time": "2025-05-09T14:06:56Z",
      "expires": "2025-05-09T14:16:56Z",
      "state": "healthy"
    },
    {
      "source": "StartProvisionWatcher",
      "time": "2025-05-09T14:06:09Z",
      "expires": "2025-05-09T14:16:09Z",
      "state": "healthy"
    }
  ],
  "retrievedAt": "2025-05-09T14:06:56Z"
}
```

</details>
<br />

To view this information in a visual format, visit your SCIM bridge URL in a web browser. Sign in with your bearer token, then you can view status information and download container log files.

## Step 6: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM bridge

To update SCIM bridge, connect to your Kubernetes cluster and run the following command:

```sh
kubectl set image deploy/op-scim-bridge op-scim-bridge=1password/scim:v2.9.13
```

> **Note**
>
> You can find details about the changes on the [SCIM bridge releases notes website](https://releases.1password.com/provisioning/scim-bridge/). The most recent version should be pinned in the
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

3. [Test your SCIM bridge](#step-5-test-your-scim-bridge) using the new bearer token associated with the regenerated `scimsession` file.
4. Update your identity provider configuration with your new bearer token.

## Appendix: Resource recommendations

The 1Password SCIM Bridge Pod should be vertically scaled when provisioning a large number of users or groups. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 125m  | 512M   |
| High      | 1,000–5,000     | 500m  | 1024M  |
| Very high | >5,000          | 1000m | 1024M  |

If provisioning more than 1,000 users, the resources assigned to the SCIM bridge container should be updated as recommended in the above table. The resources specified for the Redis container do not need to be adjusted.

Resource configuration can be updated in place:

### Default resources

Resources for the SCIM bridge container are defined in [`op-scim-deployment.yaml`](https://github.com/1Password/scim-examples/blob/master/kubernetes/op-scim-deployment.yaml):

```yaml
spec:
  ...
  template:
    spec:
      ...
      containers:
        - name: op-scim-bridge
          ...
          resources:
            requests:
              cpu: 125m
              memory: 512M
            limits:
              memory: 512M
          ...
```

After making any changes to the Deployment resource in your cluster, you can apply the unmodified manifest to revert to the default specifications defined above:

```sh
kubectl apply --filename=./op-scim-deployment.yaml
```

### High volume

For provisioning up to 5,000 users:

```sh
kubectl set resources deployment/op-scim-bridge --requests=cpu=512m,memory=1024M --limits=memory=1024M
```

### Very high volume

For provisioning more than 5,000 users:

```sh
kubectl set resources deployment/op-scim-bridge --requests=cpu=1000m,memory=1024M --limits=memory=1024M
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

Save the public certificate along with any provided intermediate certificates from your certificate authority to the file `certificate.pem`, and the private key in `key.pem`.

The provided intermediate(s) from your certificate authority must be _after_ the leaf cert that applies to your SCIM bridge deployment URL.


> [!IMPORTANT]
> Without the intermediate(s) included, some identity providers (ex. [Okta](https://support.okta.com/help/s/article/receiving-pkix-path-building-failed-setting-up-a-hook-or-scim-server?language=en_US)) will be unable to validate your TLS certificate for your SCIM bridge. 

<details>
   <summary>An example certificate.pem file</summary>
   
```
-----BEGIN CERTIFICATE----- # The certificate for example.com
MIIFmzCCBSGgAwIBAgIQCtiTuvposLf7ekBPBuyvmjAKBggqhkjOPQQDAzBZMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMTMwMQYDVQQDEypEaWdp
Q2VydCBHbG9iYWwgRzMgVExTIEVDQyBTSEEzODQgMjAyMCBDQTEwHhcNMjUwMTE1
MDAwMDAwWhcNMjYwMTE1MjM1OTU5WjCBjjELMAkGA1UEBhMCVVMxEzARBgNVBAgT
CkNhbGlmb3JuaWExFDASBgNVBAcTC0xvcyBBbmdlbGVzMTwwOgYDVQQKEzNJbnRl
cm5ldCBDb3Jwb3JhdGlvbiBmb3IgQXNzaWduZWQgTmFtZXMgYW5kIE51bWJlcnMx
FjAUBgNVBAMMDSouZXhhbXBsZS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNC
AASaSJeELWFsCMlqFKDIOIDmAMCH+plXDhsA4tiHklfnCPs8XrDThCg3wSQRjtMg
cXS9k49OCQPOAjuw5GZzz6/uo4IDkzCCA48wHwYDVR0jBBgwFoAUiiPrnmvX+Tdd
+W0hOXaaoWfeEKgwHQYDVR0OBBYEFPDBajIN7NrH6o/NDW0ZElnRvnLtMCUGA1Ud
EQQeMByCDSouZXhhbXBsZS5jb22CC2V4YW1wbGUuY29tMD4GA1UdIAQ3MDUwMwYG
Z4EMAQICMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
UzAOBgNVHQ8BAf8EBAMCA4gwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMC
MIGfBgNVHR8EgZcwgZQwSKBGoESGQmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9E
aWdpQ2VydEdsb2JhbEczVExTRUNDU0hBMzg0MjAyMENBMS0yLmNybDBIoEagRIZC
aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsRzNUTFNFQ0NT
SEEzODQyMDIwQ0ExLTIuY3JsMIGHBggrBgEFBQcBAQR7MHkwJAYIKwYBBQUHMAGG
GGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBRBggrBgEFBQcwAoZFaHR0cDovL2Nh
Y2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsRzNUTFNFQ0NTSEEzODQy
MDIwQ0ExLTIuY3J0MAwGA1UdEwEB/wQCMAAwggF7BgorBgEEAdZ5AgQCBIIBawSC
AWcBZQB0AA5XlLzzrqk+MxssmQez95Dfm8I9cTIl3SGpJaxhxU4hAAABlGd6v8cA
AAQDAEUwQwIfJBcPWkx80ik7uLYW6OGvNYvJ4NmOR2RXc9uviFPH6QIgUtuuUenH
IT5UNWJffBBRq31tUGi7ZDTSrrM0f4z1Va4AdQBkEcRspBLsp4kcogIuALyrTygH
1B41J6vq/tUDyX3N8AAAAZRnesAFAAAEAwBGMEQCIHCu6NgHhV1Qvif/G7BHq7ci
MGH8jdch/xy4LzrYlesXAiByMFMvDhGg4sYm1MsrDGVedcwpE4eN0RuZcFGmWxwJ
cgB2AEmcm2neHXzs/DbezYdkprhbrwqHgBnRVVL76esp3fjDAAABlGd6wBkAAAQD
AEcwRQIgaFh67yEQ2lwgm3X16n2iWjEQFII2b2fpONtBVibZVWwCIQD5psqjXDYs
IEb1hyh0S8bBN3O4u2sA9zisKIlYjZg8wjAKBggqhkjOPQQDAwNoADBlAjEA+aaC
RlPbb+VY+u4avPyaG7fvUDJqN8KwlrXD4XptT7QL+D03+BA/FUEo3dD1iz37AjBk
Y3jhsuLAW7pWsDbtX/Qwxp6kNsK4jh1/RjvV/260sxQwM/GM7t0+T0uP2L+Y12U=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE----- # The intermediate certificate for example.com provided by your CA
MIIDeTCCAv+gAwIBAgIQCwDpLU1tcx/KMFnHyx4YhjAKBggqhkjOPQQDAzBhMQsw
CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
ZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBHMzAe
Fw0yMTA0MTQwMDAwMDBaFw0zMTA0MTMyMzU5NTlaMFkxCzAJBgNVBAYTAlVTMRUw
EwYDVQQKEwxEaWdpQ2VydCBJbmMxMzAxBgNVBAMTKkRpZ2lDZXJ0IEdsb2JhbCBH
MyBUTFMgRUNDIFNIQTM4NCAyMDIwIENBMTB2MBAGByqGSM49AgEGBSuBBAAiA2IA
BHipnHWuiF1jpK1dhtgQSdavklljQyOF9EhlMM1KNJWmDj7ZfAjXVwUoSJ4Lq+vC
05ae7UXSi4rOAUsXQ+Fzz21zSDTcAEYJtVZUyV96xxMH0GwYF2zK28cLJlYujQf1
Z6OCAYIwggF+MBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFIoj655r1/k3
XfltITl2mqFn3hCoMB8GA1UdIwQYMBaAFLPbSKT5ocXYrjZBzBFjaWIpvEvGMA4G
A1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwdgYI
KwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
b20wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
Q2VydEdsb2JhbFJvb3RHMy5jcnQwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2Ny
bDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0R2xvYmFsUm9vdEczLmNybDA9BgNVHSAE
NjA0MAsGCWCGSAGG/WwCATAHBgVngQwBATAIBgZngQwBAgEwCAYGZ4EMAQICMAgG
BmeBDAECAzAKBggqhkjOPQQDAwNoADBlAjB+Jlhu7ojsDN0VQe56uJmZcNFiZU+g
IJ5HsVvBsmcxHcxyeq8ickBCbmWE/odLDxkCMQDmv9auNIdbP2fHHahv1RJ4teaH
MUSpXca4eMzP79QyWBH/OoUGPB2Eb9P1+dozHKQ=
-----END CERTIFICATE-----
```
</details>


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

#### If you already deployed your SCIM bridge

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

### Advanced Redis configuration

If you are using an external Redis cache with your SCIM bridge and need additional configuration options, you can use the following environment variables in place of `OP_REDIS_URL`. These environment variables may be especially helpful if you need support for URL-unfriendly characters in your Redis credentials. `OP_REDIS_URL` must be unset, otherwise the following environment variables will be ignored.

These values can be set in [`op-scim-config.yaml`](./op-scim-config.yaml)

> **Note**
>
> If `OP_REDIS_URL` has any value, the environment variables below are ignored.

- `OP_REDIS_HOST`: overrides the default hostname of the redis server (default: `redis`). It can be either another hostname, or an IP address.
- `OP_REDIS_PORT`: overrides the default port of the redis server connection (default: `6379`).
- `OP_REDIS_USERNAME`: sets a username, if any, for the redis connection (default: `(null)`).
- `OP_REDIS_PASSWORD`: Sets a password, if any, for the redis connection (default: `(null)`). Can accommodate URL-unfriendly characters that `OP_REDIS_URL` may not accommodate.
- `OP_REDIS_ENABLE_SSL`: Optionally enforce SSL on redis server connections (default: `false`) (Boolean `0` or `1`).
- `OP_REDIS_INSECURE_SSL`: Set whether to allow insecure SSL on redis server connections when `OP_REDIS_ENABLE_SSL` is set to `true`. This may be useful for testing or self-signed environments (default: `false`) (Boolean `0` or `1`).

#### If you already deployed your SCIM bridge

You can unset `OP_REDIS_URL` and set any of the above environment variables directly to reboot SCIM bridge and connect to the specified Redis server:

_Example command:_

```sh
kubectl set env deploy/op-scim-bridge OP_REDIS_URL="" \
OP_REDIS_HOST="hostname" \
OP_REDIS_USERNAME="sherlock_admin" \
OP_REDIS_PASSWORD="apv.zbu8wva8gwd1EFC-fake.p@ssw0rd" \
OP_SSL_ENABLED="0"
```

Delete the cluster resources for Redis, if required:

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

## Troubleshooting

When cluster resources are updated in place, Kubernetes will create a new revision alongside an existing workload before replacing the existing revision. If there are not enough available resources in the cluster to schedule both revisions, the update can hang until they become available. This can happen when vertically scaling a Deployment or updating to a new SCIM bridge image version.

If there are enough resources in the cluster available to schedule the new Pod revision, you can restart the Deployment to evict the existing Pod, free up the resources, and allow the new Pod to start:

```sh
kubectl rollout restart deployment/op-scim-bridge
```
