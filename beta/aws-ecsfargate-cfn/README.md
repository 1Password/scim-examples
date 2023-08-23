# Deploy 1Password SCIM Bridge with AWS CloudFormation

This example describes how to deploy 1Password SCIM Bridge using [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html) on Amazon Elastic Container Service (ECS) with AWS Fargate.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`op-scim-bridge.yaml`](./op-scim-bridge.yaml): a [CloudFormation template](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-templates) for 1Password SCIM Bridge.

## Overview

The included template can be used to deploy 1Password SCIM Bridge as a [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-stacks) using the [AWS CloudFormation console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console.html) or [the AWS Command Line Interface (AWS CLI)](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-cli.html). The CloudFormation template will create and configure the following resources in your AWS account:

- a VPC (with a `10.0.0.0/16` CIDR block by default)
- 2 public subnets (each with `/20` CIDR blocks within this range), spanned across two availability zones in the current or selected region
- an internet gateway
- an Application Load Balancer (ALB)
- an ECS task with associated container definitions for 1Password SCIM Bridge and the requred Redis cache
- an ECS service and ECS cluster for the above task
- a target group targeting the SCIM bridge container
- 2 security groups to restrict traffic to and from the ALB and the ECS cluster, respectively
- an AWS Certificate Manager (ACM) TLS certificate for the ALB
- 2 Route 53 DNS records:
  - for the domain name of your SCIM bridge (e.g. `scim.example.com`)
  - to validate the requested ACM certificate
- an AWS Secrets Manager secret to store the `scimsession` credentials for your SCIM bridge
- a CloudWatch log group to capture logs in streams from each of the SCIM bridge and Redis containers
- required IAM roles

This template is a working example to be used as a base for your SCIM bridge deployment and may need to be customized to meet your specific requirements.

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > **Note**
  >
  > 👀 Try 1Password Business **free** for 14 days: <https://start.1password.com/sign-up/business>
- An AWS account with the permissions and available quota to create and manage the described resources
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (if you want to manage the deployment using a terminal or script).

## Getting started

Before deploying 1Password SCIM Bridge, consult the [Preparation Guide](/PREPARATION.md) in this repository. Since this CloudFormation template will create all necessary resources, you do not need to seperately create a DNS record for your SCIM bridge, nor use its certificate manager component to create and manage a TLS certificate.

1. Clone this repository and switch to this directory:

   ```sh
   git clone https://github.com/1Password/scim-examples.git
   cd ./scim-examples/beta/aws-ecsfargate-cfn
   ```

   or, download the template file [`op-scim-bridge.yaml`](./op-scim-bridge.yaml) to a working directory on your computer.
2. Follow the steps in [Automate provisioning in 1Password Business using SCIM](https://support.1password.com/scim/#step-1-set-up-and-deploy-1password-scim-bridge) to generate credentials for your SCIM bridge.
3. Save the `scimsession` credentials file and the associated bearer token as items in your 1Password account.
4. Download the `scimsession` file to the same working directory.

## 🏗️ Deploy 1Password SCIM Bridge

Create a stack for your SCIM bridge [in the AWS CloudFormation console](#-use-the-aws-cloudformation-console) or [using AWS CLI](#-use-aws-cli):

### 🖼 Use the AWS CloudFormation console

For a GUI deployment, you can create a stack in the CloudFormation console.

1. [Create a stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create) with new resources:
   - In the "Specify template" section, choose "Upload a template file".
   - Click "↑ Choose file" and upload the `op-scim-bridge.yaml` file from the working directory on your computer.
   - Click Next.
2. Specify stack details. Use the following options (for everything else, use the provided defaults or your own preferences):
   - Type `op-scim-bridge` in the "Stack name" field. CloudFormation will use the stack name (or a truncated version where needed) as a prefix when naming the created AWS resources.
     > **Note**
     >
     > 📄 We use `op-scim-bridge` as a shorthand for 1Password SCIM Bridge throughout our examples and supporting documentation, but the choice is arbitrary.
   - Select the Route 53 hosted zone for DNS records.
   - Replace `scim.example.com` with a domain name for your SCIM bridge that is in the domain of this hosted zone.
   - Open the `scimsession` file from your working directory in a text editor. Select all text in the file and copy it to your clipboard. Paste the contents into the `scimession` field (it will be masked on input), then click Next.
3. Configure stack options:
   - Click "Add new tag" to add any tags you require to all supported resources in the stack.
   - Review the options, using the provided defaults or your own options as required or preferred. Click Next.
4. Review the stack configuration. When you're finished, click "I acknowledge that AWS CloudFormation might create IAM resources." below Capabilities, then click Submit.

The console will display the stack status as `ℹ️ CREATE_IN_PROGRESS` during the deployment. The stack is expected to take several minutes to create (generally a bit more than 5 minutes when this document was written). After the stack is created, the status will change to `✅ CREATE_COMPLETE`.

### 💻 Use AWS CLI

You can alternatively deploy 1Password SCIM Bridge with a single AWS CLI command.

*Example command:*

```sh
aws cloudformation deploy \
    --template-file ./op-scim-bridge.yaml \
    --stack-name op-scim-bridge \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        Route53HostedZoneID=Z2ABCDEF123456 \
        DomainName=scim.example.com \
        scimsession=$(cat ./scimsession) \
        # VPCCIDR=10.0.0.0/16 \
    # --tags \
    #     Key1=Value1 \
    #     Key2=Value2
```

Edit the example above with the following:

1. If the template file was saved with a different file name or somewhere other than the working directory, replace `./op-scim-bridge.yaml` with the actual path (for example, `--template-file path/to/template.file`).
2. If you prefer, set your own value for the `--stack-name` flag in the above command to choose your own name (for example, `--stack-name your-stack-name`). CloudFormation will use the stack name (or a truncated version where needed) as a prefix when naming the created AWS resources.
   > **Note**
   >
   > 📄 We use `op-scim-bridge` as a shorthand for 1Password SCIM Bridge throughout our examples and supporting documentation, but the choice is arbitrary.
3. Leave the default value for the VPC CIDR range (`VPCCIDR`). If you require something different for your environment, you can uncomment this line and replace the CIDR range with your own value.
4. Replace `Z2ABCDEF123456` with the ID of the Route 53 hosted zone for DNS records.
5. Replace `scim.example.com` with a domain name for your SCIM bridge that is in the domain of this hosted zone.
6. Ensure your `scimsession` file is located in the working directory, or replace the path specified in the subshell command (for example, `scimsession=$(cat path/to/scimsession.filename)`).
   > **Note**
   >
   > 💻 If you saved your `scimsession` file as an item in your 1Password account, you can [use 1Password CLI to pass this value](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets). For example: `scimsession=$(op read "op://Private/scimsession file/scimsession")`
7. Optionally, uncomment the appropriate lines and add tags as key-value pairs to apply to all supported resources in the stack.

After you run the command, you should see:

> ```sh
> Waiting for changeset to be created..
> Waiting for stack create/update to complete
> ```

More detailed information is available in [the CloudFormation console](https://console.aws.amazon.com/cloudformation/home#/stacks). A success message will be returned when the stack is created, for example:

> ```sh
> Successfully created/updated stack - op-scim-bridge
> ```

## Test your SCIM bridge

A clickable link of the URL for your SCIM bridge is available in the Outputs tab of the CloudFormation console (for example, <https://scim.example.com/>). You can sign in to this URL with the bearer token for your SCIM bridge to test the connection, view status information, or retrieve logs. You can also send an authenticated SCIM API request to your SCIM bridge from the command line.

*Example command:*

```sh
curl --header "Authorization: Bearer mF_9.B5f-4.1JqM" https://scim.example.com/Users
```

Replace `mF_9.B5f-4.1JqM` with your bearer token and `scim.example.com` with the domain name of your SCIM bridge in the example above.

> **Note**
   >
   > 💻 If you saved your bearer token as an item in your 1Password account, you can [use 1Password CLI to pass the bearer token](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets) instead of writing it out in the console. For example: `--header "Authorization: Bearer $(op read "op://Private/bearer token/credential")"`

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

## Connect your identity provider

Use your SCIM bridge URL and bearer token to [connect your identity provider to 1Password SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Appendix

### Update 1Password SCIM Bridge

To update to the latest version of 1Password SCIM Bridge, update your stack with a new value for the `SCIMBridgeVersion` parameter. You can [use the AWS console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks.html) or AWS CLI. Use the latest template from this repository ([`op-scim-bridge.yaml`](./op-scim-bridge.yaml)) and update the value of the "1Password SCIM Bridge version" parameter (`SCIMBridgeVersion`). Use the existing values for everything else.

*Example command:*

```sh
aws cloudformation deploy \
    --template-file ./op-scim-bridge.yaml \
    --stack-name op-scim-bridge \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides SCIMBridgeVersion=v2.8.3
```

> **Note**
>
> Our [1Password SCIM Bridge release notes page](https://app-updates.agilebits.com/product_history/SCIM) does not include `v` in each release version, but this character must be included in the value of the `SCIMBridgeVersion` parameter to match the corresponding [image tag in Docker Hub](https://hub.docker.com/r/1password/scim/tags):
>
> - ✅ `v2.8.3`
> - ❌ `2.8.3`
