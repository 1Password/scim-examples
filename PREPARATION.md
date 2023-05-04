# Preparing to deploy 1Password SCIM Bridge

*Learn how to prepare your environment and 1Password account to integrate with 1Password SCIM Bridge.*

## Overview

1Password SCIM Bridge uses the [SCIM protocol](http://www.simplecloud.info/) to act as an intermediary between your identity provider, such as Okta or Azure Directory, and your 1Password instance. It allows you to centralize user management to your identity provider so you can automatically provision and manage users and groups in 1Password based on assignments in your identity provider.

### Technical components

For general deployment, the SCIM bridge requires three components:

* the `op-scim` service
* a [redis](https://redis.io/) cache
* a domain name (for example, `op-scim-bridge.example.com`)

### DNS record

You'll need to be able to create a DNS record with the SCIM bridge domain name you want to use. However, you'll need to have the IP address of the host, so the bridge will need to be deployed first, unless you have a static IP already assigned. Follow the steps in the deployment guide you use for guidelines on when to finish setting up your DNS record.

### TLS certificates

Identity providers typically require a TLS certificate when communicating with the SCIM bridge. By default, TLS certificates are handled through a complimentary [Let's Encrypt](https://letsencrypt.org/) service integration, which automatically generates and renews a certificate based on the domain you're using.

There are two ways you can use the Let's Encrypt service to issue a certificate for your SCIM bridge:

#### TLS-ALPN-01

The default and easiest option is the [TLS-ALPN-01](https://letsencrypt.org/docs/challenge-types/#tls-alpn-01) challenge type. When you set up the SCIM bridge, you'll set the `OP_TLS_DOMAIN` configuration variable to the domain name you've selected for your bridge (for example, `op-scim-bridge.example.com`).

In the background, Let's Encrypt will make sure it can communicate with the SCIM bridge through port `443`  and receive some special challenge tokens from the bridge. This completes the authentication portion and Let's Encrypt issues the SCIM bridge a new TLS certificate, which is automatically loaded. The SCIM bridge then stores this certificate in the `redis` cache for later use.

To continue using this challenge type, you'll need to **keep port 443 accessible to the internet at all times**. If you have specific requirements, such as an internally-hosted identity provider, this can become an issue, so you may want to provide your own certificates or consider DNS-01.

#### DNS-01

`DNS-01` doesn't require the SCIM bridge to be publicly-accessible. This also allows for more advanced firewall techniques to be applied if required. While not as convenient as `TLS-ALPN-01`, it can open up more options for your deployment environment.

With this method, the SCIM bridge must be able to communicate with one of the DNS providers currently supported. As of April 2023, the supported providers are Google Cloud DNS, CloudFlare DNS, and Azure DNS.

Importantly, each DNS service tends to have its own unique way of configuring credentials to authenticate with them. For example, CloudFlare DNS typically only requires an API key (1 credential), whereas Azure DNS requires five separate configuration parameters to fully authenticate with the service.

During the authentication procedure with Let's Encrypt, the SCIM bridge modifies the DNS records of a given name (for example, `op-scim-bridge.example.com`) with certain records that Let's Encrypt is expecting to confirm DNS ownership. Once DNS ownership is confirmed, Let's Encrypt issues a certificate as usual, and the SCIM bridge removes those temporary DNS records.

To use this method, you'll provide secrets for the DNS service you choose during setup process. You can find an example configuration file [here](./dns01.example.json).

## Considerations

There are a few things to consider before you deploy 1Password SCIM Bridge:

* After you turn on provisioning, your identity provider will  become the _authoritative source_ of user and group information for your 1Password account. You'll need to change the _display name_ and _account status_ of users in your identity provider; it's not currently possible to do this on 1Password.com when provisioning is turned on. You can still [recover accounts](https://support.1password.com/recovery/) for users who can't sign in.
* Do not attempt to perform a provisioning sync until the setup has been completed.
* You should only have one instance of 1Password SCIM Bridge running at a time. The SCIM bridge is not considered a high-availability service and running multiple SCIM bridges is not supported.
* 1Password SCIM Bridge Version 1.6.0 and newer allow you to enforce email address changes through your identity provider. When you do, users will be required to confirm email changes the next time they sign in to 1Password since their email address is used when generating the encryption keys for their account.

For more information on our security model, you can read the [1Password Security Design White Paper](https://1passwordstatic.com/files/security/1password-white-paper.pdf).

## Clone this repository

Before you start the deployment, clone this repository to make sure you have all the files you need and familiarize yourself with the contents of the deployment method you've selected.

From the command line:

```
git clone https://github.com/1Password/scim-examples.git
```

Alternatively, you can download a .zip of the repo by choosing Code > Download ZIP.

## Prepare your 1Password Account

Sign in to your 1Password account on 1Password.com and click [Integrations](https://start.1password.com/integrations/directory/) in the sidebar, then choose your identity provider and follow the onscreen instructions. Before you begin, you can also learn more about the steps to [automate provisioning with 1Password Business using SCIM](https://support.1password.com/scim/).

### Security (IMPORTANT)

All SCIM requests must be secured via TLS using an API gateway (self-configured web server) or the provided load balancer.

You'll be provided with two secrets:

* a `scimsession` file
* a bearer token

The `scimsession` is created for you during setup and it contains the credentials for the automated provisioning integration. This integration will create, confirm, and suspend users, and create and manage access to groups. These secrets are required to connect to the 1Password service.

**Do not share these secrets!**

The bearer token must be provided to your Identity Provider, but beyond that it should be kept safe and **not shared with anyone else.** The `scimsession` file should only be shared with the SCIM bridge itself.

These secrets can be used to authenticate as the automated provisioning integration. It is a major security concern if they're not kept safe.

Learn more [about 1Password SCIM Bridge security](https://support.1password.com/scim-security/).

### If you have a Provision Manager

If you were previously using a Provision Manager with the SCIM bridge integration, learn how to [upgrade your provisioning integration](https://support.1password.com/cs/upgrade-provisioning-integration/).
