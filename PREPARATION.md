# Preparing to deploy your 1Password SCIM Bridge

This guide will help you prepare to deploy your 1Password SCIM Bridge.

## Decide on URL and email address

There are a few pieces of information you'll want to decide on before beginning the setup process:

* Your SCIM bridge domain name. (example: `op-scim-bridge.example.com`)
* An email to use for the automatically-created Provision Manager user. (example: `op-scim@example.com`)


## High-Level Overview

The SCIM bridge relies on the [SCIM protocol](http://www.simplecloud.info/), and acts as an intermediary between your Identity Provider - Azure Active Directory, Okta, and others - and your 1Password instance.

It allows for automatic provisioning and deprovisioning of your 1Password user accounts based on what accounts you have assigned in your Identity Provider, providing a way to centralize your organization's 1Password account with other services you may be using.

For general deployment, the SCIM bridge requires three things to function correctly:
* the `op-scim` service itself
* a [Redis](https://redis.io/) cache
* a load balancer or web server to handle TLS connections on port 443

SSL certificates are handled through the [https://letsencrypt.org/](LetsEncrypt) service which automatically generates and renews an SSL certificate based on the domain name you've decided on. On your firewall, you should ensure that the service can access Port 80 and Port 443, as Port 80 is required for the LetsEncrypt service to complete its domain challenge and issue your SCIM bridge an SSL certificate.

Note that a TLS connection is still mandatory for connecting to the 1Password service.


## Clone this repository

You should clone this repository to ensure you have all the files needed to begin deployment. You should also familiarize yourself with the contents of the deployment method you've selected to ensure you have a full idea of what the deployment process will do.

From the command line:

```
git clone https://github.com/1Password/scim-examples.git
```

Alternatively, you can download a .zip of the project by clicking the "Clone or download" button.


## Caveats

There are a few common issues that pop up when deploying the SCIM Bridge.

* Do not create the Provision Manager user manually. Let the setup process create the Provision Manager user for you **automatically.**
* When the Provisioning setup asks you for an email address for the new Provision Manager user it creates for you automatically, use a **dedicated email address** (for example: `op-provision-manager@example.com`) to handle this account. It is _not advised_ to use any personal email address.
* You should **never** need to log into this Provision Manager account manually.
* Do not attempt to perform a provisioning sync until the setup has been completed.


## Prepare your 1Password Account

Log in to your 1Password account [using this link](https://start.1password.com/settings/provisioning/setup). It will take you to the setup page for the SCIM bridge. Follow the instructions there.

During this process, the setup will guide you through the following process:

* Automatically creating a Provision Managers group
* Automatically creating a Provision Manager user
* Generating your SCIM bridge credentials


### Security (IMPORTANT)

There are a few specific considerations with respect to security.

All SCIM requests must be secured via TLS using an API gateway (self-configured web server) or the provided load balancer.

Anonymous access to 1Password is not supported. You must use the provided secrets to authenticate with the SCIM Bridge and 1Password service.

You will be provided with two separate secrets:

* a `scimsession` file
* a bearer token

The `scimsession` file contains the credentials for the new Provision Manager user the setup process automatically created for you. This user will create, confirm, and suspend users, and create and manage access to groups.

**Do not share these secrets!**

The bearer token must be provided to your Identity Provider, but beyond that it should be kept safe and **not shared with anyone else.** The `scimsession` file should only be shared with the SCIM bridge itself.

These secrets can be used to authenticate as the Provision Manager user. While vaults cannot be compromised in this way, it is still a major security concern if they're not kept safe. If, for any reason, you think the secrets may have been leaked, please regenerate them by following the setup guide again through the link above.

**IMPORTANT:** To reiterate, please keep these secrets in a secure location, and **don't share them** with anyone unless absolutely necessary.


## DNS record

You will need to be able to create a DNS record with the SCIM bridge domain name decided. However, you'll need to have the IP address of the host, which necessitates deploying the SCIM bridge first, unless you have a static IP already assigned. Follow the steps in each respective deployment guide on when to finish setting up your DNS record.
