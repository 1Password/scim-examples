# Deploy 1Password SCIM Bridge using Docker

_Learn how to deploy 1Password SCIM Bridge on a server or virtual machine using Docker Engine._

This example describes how to deploy 1Password SCIM Bridge as a [stack](https://docs.docker.com/engine/swarm/stack-deploy/) in a single-node [Docker Swarm](https://docs.docker.com/engine/swarm/key-concepts/#what-is-a-swarm). The base stack includes two [services](https://docs.docker.com/engine/swarm/how-swarm-mode-works/services/) (one each for the SCIM bridge container and the required Redis cache) and a [Docker secret](https://docs.docker.com/engine/swarm/secrets/) for the `scimsession` credentials. The server is configured to receive traffic directly from the public internet with Docker acting as a reverse proxy to the SCIM bridge container with a TLS certificate from Let's Encrypt. Other common configurations are also included for convenience.

## Before you begin

Review the [Preparation Guide](/PREPARATION.md) at the root of this repository. The open source [Docker Engine](https://docs.docker.com/engine/) tooling can be used with [any supported Linux distribution](https://docs.docker.com/engine/install/#supported-platforms). AMD64 or ARM64 architecture is required by the SCIM bridge container image. The base configuration requires at least 0.5 vCPU and 1 GB RAM for the container workloads, plus additional overhead for the operating system and Docker Engine.

Create a public DNS record (for example, `op-scim-bridge.example.com`) that points to a publicly available endpoint for the server.

## Step 1: Prepare the server

Connect to the machine that you will be using as the host for your SCIM bridge to set up Docker:

> [!TIP]
> 🔑 You can use use the [1Password SSH agent](https://developer.1password.com/docs/ssh/get-started) to authenticate the
> connection to the server (and other SSH workflows).

1. If you haven't already done so, [install Docker Engine](https://docs.docker.com/engine/install/#supported-platforms) on the server (Docker Desktop is not required or expected).
2. Follow the [post-install steps](https://docs.docker.com/engine/install/linux-postinstall/) in the documentation to enable running Docker as a non-root user and ensure that Docker Engine starts when the server boots.
3. Run this command to [create a swarm](https://docs.docker.com/engine/swarm/swarm-mode/#create-a-swarm) with a single node:

   ```sh
   docker swarm init --advertise-addr 127.0.0.1
   ```

4. Clone this repository and switch to this directory:

   ```sh
   git clone https://github.com/1Password/scim-examples.git
   cd ./scim-examples/docker
   ```

## Step 2: Configure your 1Password SCIM Bridge deployment

1. On the computer where you downloaded the file from [the Automated User Provisioning setup](https://start.1password.com/integrations/directory/), copy the `scimsession` credentials file to the working directory on your server. For example, using SCP:

   ```sh
   scp ./scimsession op-scim-bridge.example.com:scim-examples/docker/scimsession
   ```

2. On the server, open `scim.env` in your favourite text editor. Set the value of `OP_TLS_DOMAIN` to the fully qualififed domain name of the public DNS record for your SCIM bridge created in [Before you begin](#before-you-begin)). For example:

   ```dotenv
   # ...
   OP_TLS_DOMAIN=op-scim-bridge.example.com

   # ...
   ```

   Save the file.

## Step 3: Deploy 1Password SCIM Bridge

Use the Compose template to output a canonical configuration for use with Docker Swarm and create the stack from this configuration inline. Your SCIM bridge should automatically acquire and manage a TLS certificate from Let's Encrypt on your behalf:

```sh
docker stack config --compose-file ./compose.template.yaml | docker stack deploy --compose-file - op-scim-bridge
```

Run this command on the server to view logs from the service for the SCIM bridge container:

```sh
docker service logs op-scim-bridge_scim --raw
```

## Step 4: Test your SCIM bridge

Your **SCIM bridge URL** is based on the fully qualified domain name of the DNS record created in [Before you begin](#before-you-begin). For example: `https://op-scim-bridge.example.com`. You can sign with your bearer token at your SCIM bridge URL in a web browser to view status information and download log files.

You can also check the status of your SCIM bridge with a bearer token authenticated request to its `/health` endpoint. Depending on your DNS and networking configuration, you may need to send the request from another device (for example, your computer) to reach the SCIM bridge URL:

1. Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://op-scim-bridge.example.com` with your SCIM bridge URL to store them as environment variable values for the current terminal session:

   ```sh
   # The below commmand includes a prepended space so that the bearer token is not saved to your terminal history
    export OP_SCIM_TOKEN="mF_9.B5f-4.1JqM"
   export OP_SCIM_BRIDGE_URL="https://op-scim-bridge.example.com"
   ```

2. Use the environment variables in your request. For example, using `curl`:

   ```sh
   curl --silent --show-error --request GET --header "Accept: application/json" \
     --header "Authorization: Bearer $OP_SCIM_TOKEN" $OP_SCIM_BRIDGE_URL/health
   ```

> [!TIP]
> If you saved your bearer token to your 1Password account, you can use [secret reference
> syntax](https://developer.1password.com/docs/cli/secret-reference-syntax) with [1Password
> CLI](https://developer.1password.com/docs/cli/get-started) to securely pass it inline. For example, using [`op
read`](https://developer.1password.com/docs/cli/secret-references#with-op-read):
>
> ```sh
> export OP_SCIM_TOKEN="op://Employee/Bearer Token/credential"
> export OP_SCIM_BRIDGE_URL="https:/op-scim-bridge.example.com"
>
> curl --silent --show-error --request GET --header "Accept: application/json"  \
>   --header "Authorization: Bearer $(op read $OP_SCIM_TOKEN)" $OP_SCIM_BRIDGE_URL/health
> ```

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

## Step 5: Connect your identity provider

> [!WARNING] > **If Google Workspace is your identity provider**, additional steps are required: [connect your 1Password SCIM Bridge to Google Workspace](./google-workspace/README.md).

To finish setting up automated user provisioning, use your SCIM bridge URL and bearer token to [connect your identity provider to 1Password SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Maintenance

Quarterly review and maintenance is recommended to update the operating system, the packages for Docker Engine, and the container image for 1Password SCIM Bridge.

### Update your SCIM Bridge

To use a new version of SCIM bridge, update the `op-scim-bridge_scim` service with the new image tag from the [`1password/scim` repository on Docker Hub](https://hub.docker.com/r/1password/scim/tags):

```sh
docker service update op-scim-bridge_scim --image 1password/scim:v2.9.13
```

Your SCIM bridge should automatically reboot using the specified version, typically in a few seconds.

You can find details about the changes in each release of 1Password SCIM Bridge on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website. The most recent version should be pinned in the [`compose.template.yaml`](./compose.template.yaml) file (and in the command above in this file) in the `main` branch of this repository.

### Rotate credentials

Docker secrets are immutable and cannot be removed while in use by a Swarm service. To use new secret values in your stack, you must unmount the existing secret from the service configuration, remove the current Docker secret, and redeploy the stack to create and mount a new secret with the regenerated credentials:

1. Pause provisioning in your identity provider.
2. On the server where your SCIM bridge is deployed, update the `op-scim-bridge_scim` service definition to unnmount the the `credentials` Docker secret:

   ```sh
   docker service update op-scim-bridge_scim --secret-rm credentials
   ```

3. Remove the secret from the swarm:

   ```sh
   docker secret rm credentials
   ```

4. Copy the regenerated `scimsession` file from your 1Password account to the working directory on the server (e.g. `~/scim-examples/docker`).
5. Switch to the working directory on the server. Run the same command used to [deploy SCIM bridge](#step-3-deploy-1password-scim-bridge) to create and mount a new secret using the new file:

   ```sh
   docker stack config --compose-file ./compose.template.yaml | docker stack deploy --compose-file - op-scim-bridge
   ```

6. [Test your SCIM bridge](#step-4-test-your-scim-bridge) using the new bearer token associated with the regenerated `scimsession` file. Update your identity provider configuration with the new bearer token.

A similar process can be used to update the values for any other Docker secrets used in your configuration (e.g. when using a [self-managed TLS certificate](#self-managed-tls-certificate)).

## Advanced configurations and customizations

SCIM bridge configuration can be consumed from the container environment when the container starts.

The `scimsession` credentials file and any other files that are consumed as Docker secrets should not be committed to source control. However, the [`scim.env`](./scim.env) file, included YAML templates, and your customizations are suitable as a base for your own upstream SCIM bridge repository for your deployment.

Since swarm mode in Docker Engine uses a declarative service model, you can also apply changes to update the configuration "on the fly" from your terminal for development or debugging. Services will automatically restart tasks when their configuration is updated.

For example, to reboot your SCIM bridge with debug logging enabled:

```sh
docker service update op-scim-bridge_scim --env-add OP_DEBUG=1
```

To turn off debug logging and inject some colour into the logs in your console:

```sh
docker service update op-scim-bridge_scim \
  --env-rm OP_DEBUG \
  --env-add OP_PRETTY_LOGS=1
```

Multiple Compose files can be [merged](https://docs.docker.com/compose/multiple-compose-files/merge/) when deploying or updating a stack to modify the base configuration. Several override Compose files are included in the working folder for your convenience.

### Resource recommendations

The SCIM bridge container should be vertically scaled when provisioning a large number of users or groups. The Redis container resource specifications do not need to be adjusted. Our default resource specifications and recommended configurations for provisioning at scale are listed in the below table:

| Volume    | Number of users | CPU   | memory |
| --------- | --------------- | ----- | ------ |
| Default   | <1,000          | 0.125 | 512M   |
| High      | 1,000–5,000     | 0.5   | 1024M  |
| Very high | >5,000          | 1.0   | 1024M  |

If provisioning more than 1,000 users, the resources assigned to the SCIM bridge container should be updated as recommended in the above table.

#### Default

Resources for the SCIM bridge container are defined in [the base Compose file](./compose.template.yaml):

```yaml
services:
  # ...
  scim:
    # ...
    deploy:
      resources:
        reservations:
          cpus: "0.125"
        limits:
          memory: 512M
          # ...
```

#### High volume

When provisioning up to 5,000 users, merge the configuration from the [`compose.high-volume.yaml`](./compose.high-volume.yaml) file:

```sh
docker stack config --compose-file ./compose.template.yaml \
  --compose-file ./compose.high-volume.yaml |
  docker stack deploy --compose-file - op-scim-bridge
```

#### Very high volume

When provisioning more than 5,000 users, merge the configuration from [`compose.very-high-volume.yaml`](./compose.very-high-volume.yaml):

```sh
docker stack config --compose-file ./compose.template.yaml \
  --compose-file ./compose.very-high-volume.yaml |
  docker stack deploy --compose-file - op-scim-bridge
```

Please reach out to our [support team](https://support.1password.com/contact/) if you need help with the configuration or to tweak the values for your deployment.

### Advanced TLS configurations

All supported identity providers strictly require an HTTPS endpoint with a valid TLS certificate for the SCIM bridge URL. 1Password SCIM Bridge includes an optional CertificateManager component that terminates TLS traffic at the SCIM bridge container. By default, CertificateManager integrates with Let's Encrypt to acquire and renew TLS certificates. This strictly requires port 443 on the server to be widely available to any IP on the public internet (i.e., ingress allowed by `0.0.0.0`) so that Let's Encrypt can initiate an inbound connection to your SCIM bridge for validation on request or renewal.

Other supported options include:

#### External load balancer or reverse proxy

To terminate TLS traffic at another public endpoint and redirect traffic within a trusted network, SCIM bridge can be configured to disable the CertificateManager component and receive plain-text HTTP traffic on port 80 of the server. CertificateManager will be enabled if a value is set for the `OP_TLS_DOMAIN` variable, so any value set in `scim.env` must be removed (or this line must be commented out). The included `compose.http.yaml` file can be used to set up the port mapping when deploying (or redeploying) SCIM bridge in this configuration:

```sh
docker stack config \
  --compose-file ./compose.template.yaml \
  --compose-file ./compose.http.yaml |
  docker stack deploy --compose-file - op-scim-bridge
```

#### Self-managed TLS certificate

You may also choose to supply your own TLS certificate with CertificateManager instead of invoking Let's Encrypt. The value set for `OP_TLS_DOMAIN` must match the common name of the certificate.

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


Use the included `compose.tls.yaml` file when deploying SCIM bridge to create Docker secrets and configure SCIM bridge to use this certificate and private key when terminating TLS traffic:

```sh
docker stack config --compose-file ./compose.template.yaml \
  --compose-file ./compose.tls.yaml |
  docker stack deploy --compose-file - op-scim-bridge
```
