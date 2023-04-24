# Preparing to deploy your 1Password SCIM bridge

This guide will help you prepare to deploy your 1Password SCIM bridge.

## High-Level Overview

The SCIM bridge relies on the [SCIM protocol](http://www.simplecloud.info/), and acts as an intermediary between your Identity Provider - Azure Active Directory, Okta, and others - and your 1Password instance.

It allows for automatic provisioning and deprovisioning of your 1Password user accounts and groups based on what accounts and groups you have assigned in your Identity Provider, providing a way to centralize your organization's 1Password account with other services you may be using.

### Technical Components

For general deployment, the SCIM bridge requires three things to function correctly:

* the `op-scim` service itself
* a [redis](https://redis.io/) cache
* a domain name (example: `op-scim-bridge.example.com`)

### DNS record

You will need to be able to create a DNS record with the SCIM bridge domain name decided. However, you'll need to have the IP address of the host, which necessitates deploying the SCIM bridge first, unless you have a static IP already assigned. Follow the steps in each respective deployment guide on when to finish setting up your DNS record.

### TLS Certificates

Identity Providers typically require a TLS certificate when communicating to the SCIM bridge under most circumstances.

By default, TLS certificates are handled through a complimentary [Let's Encrypt](https://letsencrypt.org/) service integration, which automatically generates and renews an TLS certificate based on the domain name you've decided on.

There are two ways you can use Let's Encrypt service to issue a certificate for your SCIM bridge.

### TLS-ALPN-01

The default and easiest way of using Let's Encrypt with the SCIM bridge is the [TLS-ALPN-01](https://letsencrypt.org/docs/challenge-types/#tls-alpn-01) challenge type. 

During setup of the SCIM bridge, you will end up setting the `OP_TLS_DOMAIN` configuration variable to the domain name you've selected for your bridge (i.e: `op-scim-bridge.example.com`). In the background, Let's Encrypt is ensuring that it can communicate to the SCIM bridge through port `443` and receive some special challenge tokens from the bridge. This completes the authentication portion, and Let's Encrypt then issues the SCIM bridge a new TLS certificate, which is automatically loaded. The SCIM bridge then stores this certificate in the `redis` cache for later use.

To continue using this challenge type, you will **need to keep port 443 accessible to the internet at all times** for this to work. This is fine under usual circumstances, but if you have more specific requirements, such as an internally-hosted IdP, it can be somewhat troublesome unless you are able to provide your own certificates.

### DNS-01

`DNS-01` is a different authentication method which does not require the bridge to be publicly-accessible at all. Instead, the bridge must be able to communicate with one of the DNS providers currently supported by the bridge. As of April 2023, this is Google Cloud DNS, CloudFlare DNS, and Azure DNS. You would then then provide secrets for those DNS services in the setup process.

Importantly, each DNS service tends to have its own unique way of configuring credentials to authenticate with them. For example, CloudFlare DNS typically only requires an API key (1 credential), whereas Azure DNS requires five separate configuration parameters to fully authenticate with the service.

During the authentication procedure with Let's Encrypt, the SCIM bridge modifies the DNS records of a given name (i.e: `op-scim-bridge.example.com`) with certain records that Let's Encrypt is expecting to confirm DNS ownership. Once DNS ownership is confirmed, Let's Encrypt issues a certificate as usual, and the SCIM bridge removes those temporary DNS records.

The one major advantage is that the bridge does not need to be publicly-accessible at all times to ensure a TLS certificate is available. This also allows for more advanced firewall techniques to be applied if required. While not as convenient as `TLS-ALPN-01`, it can open up more options for your deployment environment.

An example configuration file can be found [here](./dns01.example.json).

## Clone this repository

You should clone this repository to ensure you have all the files needed to begin deployment. You should also familiarize yourself with the contents of the deployment method you've selected to ensure you have a full idea of what the deployment process will do.

From the command line:

```
git clone https://github.com/1Password/scim-examples.git
```

Alternatively, you can download a .zip of the project by clicking the "Clone or download" button.

## Considerations

There are a few considerations to be aware of when deploying the SCIM bridge.

* Once set up, your Identity Provider becomes the _authoritative source_ of information for your 1Password accounts. With Provisioning enabled, the ability to change the _display name_ and _account status_ are not possible through the 1Password Web UI, and must be done through your Identity Provider. You can, however, continue to issue Account Recovery requests through the 1Password Web UI with Provisioning enabled.
* Do not attempt to perform a provisioning sync until the setup has been completed.
* You should only run one instance of the SCIM bridge online at a time. The SCIM bridge is not considered a high-availablity service. Running multiple SCIM bridges is also not supported.
* With v1.6.0+ of the SCIM bridge, you can enforce e-mail address changes through your Identity Provider. Users will be required to confirm those e-mail changes the next time they log in, as their e-mail address is used when generating their encryption keys.

For more information on our security model, you can read our [security whitepaper](https://1password.com/files/1Password-White-Paper.pdf).

## Prepare your 1Password Account

Log in to your 1Password account using this link to the [Integrations Hub](https://start.1password.com/integrations). It will take you to the setup page for the SCIM bridge. Follow the instructions there.

### Security (IMPORTANT)

There are a few specific considerations with respect to security.

All SCIM requests must be secured via TLS using an API gateway (self-configured web server) or the provided load balancer.

You will be provided with two separate secrets:

* a `scimsession` file
* a bearer token

The `scimsession` file contains the credentials for the new Automated Provisioning integration the setup process automatically created for you. This user will create, confirm, and suspend users, and create and manage access to groups. These secrets are required to connect to the 1Password service.

**Do not share these secrets!**

The bearer token must be provided to your Identity Provider, but beyond that it should be kept safe and **not shared with anyone else.** The `scimsession` file should only be shared with the SCIM bridge itself.

These secrets can be used to authenticate as the Automated Provisioning integration. It is a major security concern if they're not kept safe.

**IMPORTANT:** To reiterate, please keep these secrets in a secure location (such as within 1Password), and **don't share them** with anyone unless absolutely necessary.

## Upgrading from Provision Manager

If you were previously using a Provision Manager with the SCIM bridge integration, read [this guide](https://support.1password.com/cs/upgrade-provisioning-integration/) to upgrade your account to the latest version of the integration.
