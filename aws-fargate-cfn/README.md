# Deploy 1Password SCIM bridge with AWS CloudFormation

This example describes how to deploy 1Password SCIM bridge using [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html) on Amazon Elastic Container Service (ECS) with AWS Fargate.

## In this folder

- [`README.md`](./README.md): the document that you are reading. 👋😃
- [`op-scim-bridge.yaml`](./op-scim-bridge.yaml): a [CloudFormation Template](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-templates) for 1Password SCIM bridge.

## Overview

The included template can be used to deploy 1Password SCIM bridge as a [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-stacks) using the [AWS CloudFormation console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console.html) or [the AWS Command Line Interface (AWS CLI)](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-cli.html).

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > **Note**
  >
  > Try 1Password Business free for 14 days: <https://start.1password.com/sign-up/business>
- An AWS account with the permissions and available quota to create and manage the described resources
- AWS CLI (optional)

## Deploy 1Password SCIM bridge

Use the AWS CloudFormation console to [create a stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) or deploy 1Password SCIM bridge [using AWS CLI](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-cli.html):

```sh
aws cloudformation deploy \
    --template-file ./op-scim-bridge.yaml \
    --stack-name op-scim-bridge \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides \
        Route53HostedZoneID=Z2ABCDEF123456 \
        DomainName=scim.example.com \
        scimsession=$(cat ./scimsession)
    # --tags Key=Value
```

The deployment takes several minutes (more detailed information is available in the AWS console):

> ```sh
> Waiting for changeset to be created..
> Waiting for stack create/update to complete
> ```

A success message will be returned when the stack is created:

> ```sh
> Successfully created/updated stack - op-scim-bridge
> ```

## Update 1Password SCIM bridge

To update to a new version of SCIM bridge, update your stack with a new value for the `SCIMBridgeVersion` parameter to update your SCIM bridge to the latest version. [Use the AWS console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks.html) or AWS CLI. **Only** specify the updated parameter value:

```sh
aws cloudformation deploy \
    --template-file ./op-scim-bridge.yaml \
    --stack-name op-scim-bridge \
    --capabilities CAPABILITY_IAM \
    --parameter-overrides SCIMBridgeVersion=v2.8.1
```

> Note
>
> Include the `v`