# Deploying the 1Password SCIM bridge using DigitalOcean App Platform
This document will describe how to deploy the 1Password SCIM bridge using DigitalOcean's App Platform.

## Deployment Overview

Deploying the SCIM bridge with App Platform comes with a few benefits:
* App Platform will provide and host the URL for your SCIM bridge; you will not need to setup an A record or prepare a name for a URL as noted in [PREPARATION.md](https://github.com/1Password/scim-examples/blob/master/PREPARATION.md)
* App Platfom will host the SCIM bridge for a low cost of $5/month. An additional cost will be applied for setting up Redis.
* There's no need to manage the container that the SCIM bridge will be running on.

## Preparation and Deployment
To get started with deploying the SCIM bridge using App Platform, you'll need:

* Access to your organization's DigitalOcean tenant.
* Access to your organization's GitHub account in order to fork this repository.
* Access to create a Droplet for Redis in your organization's DigitalOcean tenant.

### Step One: Setting up Redis

Before you deploy the SCIM bridge using App Platform, a Redis database must be created first using DigitalOcean's managed Redis database solution.

1. Under ```Manage``` in the left-hand navigation menu, select ```Databases``` or select the ```Create``` dropdown menu in the top right corner of your DigitalOcean tenant and select ```Databases```.
2. Choose Redis as your Database Engine.
3. Under ```Choose your Configuration```, leaving the ```Machine Type``` set to the ```Basic Nodes``` option is sufficient.
4. Choose a datacenter.
5. Enter a unique name for the Redis cluster (or use the default one provided).
6. Once you've configured the other settings on this page to your liking, click ```Create a Database Cluster```.

### Step Two: Building and Deploying using App Platform

Now that Redis has been set up, you can start the deployment process of the SCIM bridge. Be sure that you have forked this repo before continuing:

#### Setting up the forked repo:

1. Under ```Manage``` in the left-hand navigation menu, select ```Apps``` or select the ```Create``` dropdown menu in the top right corner of your DigitalOcean tenant and select Apps.
2. Select ```Launch Your App``` on the splash page. If you've already started using Apps, select ```Create App``` in the top right corner of the page.
3. Choose Github as your source. (You may be prompted to walk through an authorization process for your Github account and your DigitalOcean tenant)
4. Choose the repository that contains the files for the DigitalOcean App Platform deployment.
5. Choose the ```main``` branch.
6. You can choose to allow or deny Autodeploy code changes.
7. Click ```Next```.

***NOTE**: DigitalOcean will notify you that it cannot find an app in the repo. This is due to the fact that App Platform expects the Dockerfile to be located at the root of the repo. In this case, the Dockerfile is located in the ```digitalocean-app-platform``` directory and we need to specify that source directory in App Platform.*

8. Add ```digitalocean-app-platform``` after the ```/``` in the Source Directory field and select ```Find Directory```

#### App Configuration:

To configure your app, you will need to add the Redis database, and set two environment variables: ```OP_REDIS_URL``` and ```OP_SESSION```.
1. Click `Add a Database`.
2. Choose Previously Created DigitalOcean Database, and select the Redis database created in Step 1 under Database Cluster.
3. Leave "Add app as a trusted source" checked to automatically restrict access to the app. Click Add Database.
4. Enter the environment variables:
  * `OP_REDIS_URL`=`${<your-redis-cluster>.REDIS_URL}`
    * Replace `<your-redis-cluster>` with the name of your Redis cluster from Step 1. This will automatically bind the Redis connection string to the environment variable.
  * `OP_SESSION`=`<base64_encoded_scimsession>`
    *  The OP_SESSION variable should be set to the base64 encoded version of your scimsession file. Run the following command in a terminal to generate the scimsession in a base64 encoded format: ```cat /path/to/scimsession | base64 | tr -d "\n"```
    * The base64 encoded version of your scimsession should be returned in the terminal. Copy and paste the contents and paste them as the value of the OP_SESSION variable (do not copy the ```%``` sign at the end of the output).
4. Set the HTTP port for the app to ```3002```.
5.  Click ```Next```.
6.  Name your application.
7.  Select a region for the application/container. Click ```Next```.

#### Selecting a Tier:

* The Basic tier of App Platform is suffient for the SCIM bridge.
* Under Containers, the ```Basic Size``` is defaulted to the ```1 GB RAM | 1 vCPU``` option, however the ```512 MB RAM | 1 vCPU``` option is sufficient for this deployment.
* ```Number of Containers``` should be set to 1.
* Select ```Launch Basic App```.

#### Deployment:

* The App will begin the build and deploy process but the build will fail. This is related to the Dockerfile not being located at the root of the repo as mentioned earlier. Although the ```dockerfile_path``` is correctly specified in the ```deploy.template.yaml``` file, this is only provided to DigitalOcean's app detection system and not the build system.

In order to provide the build system with the correct path:

* Click Settings from the Apps dashboard.
* Scroll down to App Spec.
* Download the App Spec.
* Edit the file by updating the ```dockerfile_path``` value to ```/digitalocean-app-platform/Dockerfile``` and save it.
* Upload your file by clicking the ```Upload``` button in the App Spec section.
* Select `Replace`.

**The build process will automatically restart from here.**
* Once complete, you should be notified that the app ```Deployed Successfully``` and the URL for the SCIM bridge will be made available on the ```Apps Dashboard```. (You may need to refresh your page if the URL is not yet visible at this point)
* Ensure that you add the provided URL and the bearer token to your IdP and test the connection.
* Click the URL link and enter the bearer token for your SCIM bridge to start Provisioning tasks.
