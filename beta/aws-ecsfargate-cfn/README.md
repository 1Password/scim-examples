# Deploy 1Password SCIM bridge with AWS CloudFormation

This example describes how to deploy 1Password SCIM bridge using [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html) on Amazon Elastic Container Service (ECS) with AWS Fargate.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`op-scim-bridge.yaml`](./op-scim-bridge.yaml): a [CloudFormation template](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-templates) for 1Password SCIM bridge.

## Overview

The included template can be used to deploy 1Password SCIM bridge as a [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-stacks) using the [AWS CloudFormation console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console.html) or [the AWS Command Line Interface (AWS CLI)](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-cli.html).

The CloudFormation template will create and configure the following resources in your AWS account:

- a VPC (with a `10.0.0.0/16` CIDR block by default)
- 2 public subnets (each with `/20` CIDR blocks within this range), spanned across two availability zones in the current or selected region
- an internet gateway
- an Application Load Balancer (ALB)
- an ECS task with associated container definitions for 1Password SCIM bridge and the requred Redis cache
- an ECS service and ECS cluster for the above task
- a target group targeting the SCIM bridge container
- 2 security groups to restrict traffic to and from the ALB and the ECS cluster, respectively
- an AWS Certificate Manager (ACM) TLS certificate for the ALB
- 2 Route 53 DNS `A` records:
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

Before deploying 1Password SCIM bridge, consult the [Preparation Guide](/PREPARATION.md) in this repository. Since this CloudFormation template will create all necessary resources, you do not need to seperately create a DNS record for your SCIM bridge, nor use its certificate manager component to create and manage a TLS certificate.

1. Clone this repository and switch to this directory:

   ```sh
   git clone https://github.com/1Password/scim-examples.git
   cd ./scim-examples/beta/aws-ecsfargate-cfn
   ```

   or, download the template file [`op-scim-bridge.yaml`](./op-scim-bridge.yaml) to a working directory on your computer.
2. Follow the steps in [Automate provisioning in 1Password Business using SCIM](https://support.1password.com/scim/#step-1-set-up-and-deploy-1password-scim-bridge) to generate credentials for your SCIM bridge.
3. Save the `scimession` credentials file and the associated bearer token as items in your 1Password account.
4. Download the `scimsession` file to the same working directory.

## Deploy 1Password SCIM bridge

Use the AWS CloudFormation console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) or deploy 1Password SCIM bridge [using AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-cli.html), for example:

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

1. Specify a name for the stack in the console. Use the `--stack-name` flag in the above command to choose your own name if using AWS CLI (for example, `--stack-name your-stack-name`).
   > **Note**
   >
   > 📄 We use `op-scim-bridge` as a shorthand for 1Password SCIM bridge throughout our examples and supporting documentation, but the choice is arbitrary. CloudFormation will use the stack name (or a truncated version where needed) as a prefix when naming the created AWS resources.
2. Leave the default value for the VPC CIDR range (`VPCCIDR`) unless you require something different for your environment.
3. Select the Route 53 hosted zone in which to create DNS records, or replace `Z2ABCDEF123456` above with the ID of the hosted zone if using AWS CLI.
4. Replace `scim.example.com` with a domain name for your SCIM bridge that is in the domain of this hosted zone.
5. If using the console, open the `scimsession` file in a text editor and paste its contents into the `scimession` field (it will be masked on input). If using AWS CLI, ensure your `scimsession` file is located in the working directory, or update the path specified (for example, `scimsession=$(cat path/to/scimsession.filename)`).
   > **Note**
   >
   > 💻 If you saved your `scimsession` file as an item in your 1Password account, you can [use 1Password CLI to supply the contents](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets).
6. Optionally, add tags in the console or the CLI command to apply to all supported resources in the stack.

The deployment takes several minutes. If using AWS CLI to deploy, you should see:

> ```sh
> Waiting for changeset to be created..
> Waiting for stack create/update to complete
> ```

A success message will be returned when the stack is created, for example:

> ```sh
> Successfully created/updated stack - op-scim-bridge
> ```

More detailed information is available in the CloudFormation console in either case.

After the stack is created, the console will show its status as `✅ CREATE_COMPLETE`. A clickable link of the URL for your SCIM bridge is available in the Outputs tab (for example, <https://scim.example.com/>). You can sign in to this URL with the bearer token for your SCIM bridge to test, view status information, or retrieve logs.

Use this URL and bearer token to [connect yoru identity provider to 1Password SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update 1Password SCIM bridge

To update to a new version of SCIM bridge, update your stack with a new value for the `SCIMBridgeVersion` parameter to update your SCIM bridge to the latest version. [Use the AWS console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks.html) or AWS CLI. Use the latest template from this repository ([`op-scim-bridge.yaml`](./op-scim-bridge.yaml)) and update the value of the "1Password SCIM bridge version" parameter (`SCIMBridgeVersion`). Use the existing values for everything else.

```sh
aws cloudformation deploy \
    --template-file ./op-scim-bridge.yaml \
    --stack-name op-scim-bridge \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides SCIMBridgeVersion=v2.8.1
```

> **Note**
>
> Our [1Password SCIM bridge release notes page](https://app-updates.agilebits.com/product_history/SCIM) does not include `v` in each release version, but it must be included in the value of the `SCIMBridgeVersion` parameter to match the corresponding [image tag in Docker Hub](https://hub.docker.com/r/1password/scim/tags).
