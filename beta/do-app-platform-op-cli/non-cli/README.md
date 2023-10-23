# [Beta] Deploy 1Password SCIM bridge on DigitalOcean App Platform through the Web Portal

This deployment example describes how to deploy 1Password SCIM bridge as an app on DigitalOcean's [App Platform](https://docs.digitalocean.com/products/app-platform/) using the DigitalOcean web portal.

The app consists of two [resources](https://docs.digitalocean.com/glossary/resource/): a [service](https://docs.digitalocean.com/glossary/service/) for the SCIM bridge container and an [internal service](https://docs.digitalocean.com/glossary/service/#internal-services) for Redis.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃

**Table of contents:**

- [Overview](#Overview)
- [Prerequisites](#Prerequisites)
- [Getting Started](#Getting-Started)
- [Deploy 1Password SCIM bridge to App Platform](#Deploy-1Password-SCIM-Bridge-to-App-Platform-through-the-Digital-Ocean-Portal)
- [Connect your Identity Provider to your deployed SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider)
- [Appendix](#Appendix) - Including updating your SCIM bridge

## Overview

Deploying 1Password SCIM Bridge on App Platform comes with a few benefits:

- For standard deployments, App Platform will host your SCIM bridge for a predictable cost of $10 USD/month (at the time of last review).
- You do not need to manage a DNS record. DigitalOcean automatically provides a unique URL for your SCIM bridge.
- App Platform automatically handles TLS certificate management on your behalf to ensure a secure connection from your identity provider.
- You will deploy 1Password SCIM Bridge directly to DigitalOcean.

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > **Note**
  >
  > Try 1Password Business free for 14 days: <https://start.1password.com/sign-up/business>
- A DigitalOcean account with available quota for two droplets
  > **Note**
  >
  > If you don't have a DigitalOcean account, you can sign up for a free trial with starting credit: <https://try.digitalocean.com/freetrialoffer/>

## Getting started

### Generate credentials for automated user provisioning with 1Password

1. [Sign in](https://start.1password.com) to your account on 1Password.com.
2. Click [Integrations](https://start.1password.com/integrations/directory) in the sidebar.
3. Choose your identity provider from the User Provisioning section.
4. Choose "Custom deployment".
5. Use the "Save in 1Password" buttons for both the `scimsession` file and `bearer token` to save them as items in your 1Password account. 
6. Use the download icon next to the `scimsession` file to save this file on your system.

### Download the configuration file needed for deploying your SCIM bridge.

In a separate browser window, download the [op-scim-bridge.yaml](https://github.com/1Password/scim-examples/blob/solutions/bb/Define-Env-Variables/beta/do-app-platform-op-cli/op-scim-bridge.yaml) (selecting the download icon from the top right) from our GitHub repository. This file will be needed through the deployment later. 

## Deploy 1Password SCIM bridge to App Platform through the DigitalOcean Portal

To begin with, this guide will first walk you through creating a base shell for the SCIM bridge App Platform App, followed by uploading a configuration file to complete and successfully deploy the SCIM bridge in the App Plaform environment.

1. Create a new App Platfrom App from the [DigitalOcean Apps portal](https://cloud.digitalocean.com/apps) by selecting Create App. 
2. Select **Docker Hub** when presented to create resource from source code, enter `1password/scim` as the **repository** and select **Next**.
3. Select **Edit** on the Resources page next to the app name that was generated `1-password-scim`, select edit again for the name field, changing it to `op-scim-bridge`, _leaving the default name will cause an error when trying to deploy the unconfigured app_. Select Save, and back. 
4. Select **Edit Plan**, selecting the **basic** plan, followed by selecting the **$5.00/mo - Basic** option and then select **Back**. 
5. At this point after completing the above two steps, select **Next** on the Resources page. 
6. Select **Next** on the Environment page. 
7. On the **Info** page, select edit next to the **App info** section to change the name to `op-scim-bridge`, saving the changes.
8. You can also change the **Region** on the info page to a region that makes sense for your deployment. Select **Next**. 
9. Select the **Create Resources** button. 
10. The deployment of the SCIM bridge will start and eventually present an error, which is expected, due to the fact that the configuration has not been defined. 
11. On the **App Settings** page, select **Edit** next to **App Spec**. 
12. Select **Upload file**, finding the `op-scim-bridge.yaml` downloaded eariler in the [Getting Started](#Getting-Started) section. Select **Open**, followed by **Replace**. 
13. The SCIM bridge will start deploying again, and it will deploy correctly now, with the last step being to add your scimsession secret correctly to the deployment. 
14. Select the op-scim-bridge component from along the top of the page and select **Edit** next to **Environment Variables**. 
15. Delete the existing OP_SESSION environment variable. 
16. Get the Base64 encoded contents of your `scimsession` file, downloaded eariler in the [Getting Started](#Getting-Started) section. _(using the bash or PowerShell syntax for the commands)_: 

    - Using bash (macOS, or Linux):

        ```bash
        cat ./scimsession | base64
        ```

    - Using PowerShell (Windows, macOS, or Linux):

        ```pwsh
        [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $PWD.Path 'scimsession')))
        ```

    Copy the output value from the terminal to your clipboard. It will be needed to create the secret for the deployment.
17. Create a new OP_SESSION variable, pasting in the base64 value of your scimsession secret. Ensure you select the **Encrypt** checkbox, and select **Save**.
18. The deployment will get updated again, at the top of the page once the deployment is complete, you can access the Live App page, or the URL link at the top of the page next to your project name. This is your SCIM bridge URL. 
19. Click on the URL, to access and test your SCIM bridge.
18. You should be prompted to log into the SCIM bridge with your `bearer token`.

## Follow the steps to connect your Identity provider to the SCIM bridge.
 - [Connect your Identity Provider](https://support.1password.com/scim/#step-3-connect-your-identity-provider)

## Appendix

### Update 1Password SCIM bridge

The latest version of 1Password SCIM bridge is posted on our [Release Notes](https://app-updates.agilebits.com/product_history/SCIM) website, where you can find details about the latest changes. 

1. Within DigitalOcean App platform [Apps Portal](https://cloud.digitalocean.com/apps), Select your SCIM bridge, `op-scim-bridge` from the list of apps. 
2. Under Compute, select op-scim-bridge or under Settings > components > select op-scim-bridge.
3. Select **Edit** in the **Source** section. 
4. Change the version number **v2.8.4** in the **Tag** field, to match the latest version from our [SCIM Bridge Release Notes page](https://app-updates.agilebits.com/product_history/SCIM).
5. Select **Save** and the SCIM bridge will redeploy with the new version. 
6. Log into your SCIM bridge URL with your bearer token to validate in the top left hand side that you are running the version of the SCIM Bridge. (logging in with the bearer token will also update your Automated User Provisioning page with the latest access time and with the current version).

## TODO

Notes for future improvements to this deployment example:

- [ ] Add instructions for vertically scaling SCIM bridge for large-scale deployments
- [ ] Enable Google Workspace credentials for Workspace as the IdP.
