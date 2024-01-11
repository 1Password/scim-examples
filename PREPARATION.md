# Prepare to deploy 1Password SCIM Bridge

*Learn how to prepare your environment and 1Password account to use 1Password SCIM Bridge for automated user provisioning.*

## Overview

1Password SCIM Bridge uses [System for Cross-domain Identity Management](https://en.wikipedia.org/wiki/System_for_Cross-domain_Identity_Management) (SCIM) to act as an intermediary between your identity provider, such as Okta or Azure Directory, and your 1Password instance. It allows you to centralize user management to your identity provider so you can automatically provision and manage users and groups in 1Password based on assignments in your identity provider.

> **Note**
> 
> In code and on the command line, "1Password" is often referred to as `op`. For example, `op-scim`.

### Technical components

For general deployment, the SCIM bridge requires these components:

* the `op-scim` service
* a [redis](https://redis.io/) cache
* a domain name (for example, `op-scim-bridge.example.com`)

### DNS record

You'll need to create a DNS record with your SCIM bridge domain name after the bridge is deployed. Follow the steps in each respective deployment guide to finish setting up your DNS record at the appropriate time.

> **Note**
>
>Containers as a service platforms, such as Azure Container Apps and DigitalOcean App Platform, include TLS endpoint management, so you don't need to create a DNS record for these deployments.
>

### TLS certificate

Identity providers typically require a TLS certificate when communicating with the SCIM bridge. By default, TLS certificates are handled by a complimentary [Let's Encrypt](https://letsencrypt.org/) service integration, which automatically generates and renews a certificate based on the domain you're using.

> **Note**
>
>Containers as a service platforms, such as Azure Container Apps and DigitalOcean App Platform, include TLS endpoint management, so you don't need to use the optional certificate manager component.
>

If you require TLS certificate management, there are two ways you can use the Let's Encrypt service to issue a certificate for your SCIM bridge:

#### TLS-ALPN-01

The default and easiest option is the [TLS-ALPN-01](https://letsencrypt.org/docs/challenge-types/#tls-alpn-01) challenge type. When you set up the SCIM bridge, you'll set the `OP_TLS_DOMAIN` configuration variable to the domain name you've selected for your bridge (for example, `op-scim-bridge.example.com`).

In the background, Let's Encrypt will initiate an inbound HTTPS connection to your SCIM bridge on port 443 to verify the domain name and issue the SCIM bridge a new TLS certificate, which is automatically loaded and stored in the Redis cache.

To continue using this challenge type, you'll need to **keep port 443 accessible to the internet at all times**. If you have specific requirements, such as an internally-hosted identity provider, this can become an issue, so you may want to provide your own certificates or consider DNS-01.

#### DNS-01

While not as convenient as `TLS-ALPN-01`, the `DNS-01` challenge provides alternatives for your deployment environment. This challenge type does not require your SCIM bridge to be accessible by Let's Encrypt, and allows you to use your own certificate and/or more strictly constrain your firewall if preferred or required.

With this method, the SCIM bridge must be able to communicate with one of the DNS providers currently supported. As of April 2023, the supported providers are Google Cloud DNS, CloudFlare DNS, and Azure DNS.

Importantly, each DNS service tends to have its own unique way of configuring credentials to authenticate with them. For example, CloudFlare DNS typically only requires an API key (1 credential), whereas Azure DNS requires five separate configuration parameters to fully authenticate with the service.

During the authentication procedure with Let's Encrypt, the SCIM bridge modifies the DNS records of a given name (for example, `op-scim-bridge.example.com`) with certain records that Let's Encrypt is expecting to confirm DNS ownership. Once DNS ownership is confirmed, Let's Encrypt issues a certificate as usual, and the SCIM bridge removes those temporary DNS records.

To use this method, you'll provide secrets for the DNS service you choose during the setup process. You can find an example configuration file at the root of this repository: [`dns01.example.json`](/dns01.example.json).

## Considerations

There are a few things to consider before you deploy 1Password SCIM Bridge:

* You'll be provided with a bearer token, which contains the credentials for the automated provisioning integration. This integration will create, confirm, and suspend users, and create and manage access to groups. These secrets are required to connect to the 1Password service. Learn more [about 1Password SCIM Bridge security](https://support.1password.com/scim-security/).
* After you turn on provisioning, your identity provider will become the _authoritative source_ of user and group information for your 1Password account. You'll need to change the _display name_ and _account status_ of users in your identity provider; it's not currently possible to do this on 1Password.com when provisioning is turned on. You can still [recover accounts](https://support.1password.com/recovery/) for users who can't sign in.
* Do not attempt to perform a provisioning sync until the setup has been completed.
* You should only have one instance of 1Password SCIM Bridge running at a time. The SCIM bridge is not considered a high-availability service and running multiple SCIM bridges is not supported.
* 1Password SCIM Bridge Version 1.6.0 and newer allow you to enforce email address changes through your identity provider. When you do, users will be required to confirm email changes the next time they sign in to 1Password since their email address is used when generating the encryption keys for their account.

For more information on our security model, you can read the [1Password Security Design White Paper](https://1passwordstatic.com/files/security/1password-white-paper.pdf).

## Clone this repository

For most custom deployments, we recommend that you clone this repository before you start the deployment. This ensures you have all the files you need and provides an opportunity for you to familiarize yourself with the contents of the deployment method you've selected.

From the command line:

```
git clone https://github.com/1Password/scim-examples.git
```

Alternatively, you can download a .zip of the repo by choosing Code > Download ZIP.

## Prepare your 1Password account

To begin setting up automated provisioning, sign in to your 1Password account on 1Password.com and click [Integrations](https://start.1password.com/integrations/directory/) in the sidebar, then choose your identity provider and follow the onscreen instructions. Deploy your SCIM bridge using an example listed in the [README](/README.md#before-you-begin) for this repo.

Learn more [automating provisioning with 1Password using SCIM](https://support.1password.com/scim/).
