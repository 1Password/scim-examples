# Deploy 1Password SCIM Bridge with AWS CloudFormation (API Gateway)

_Learn how to deploy 1Password SCIM Bridge using [AWS CloudFormation](https://docs.aws.amazon.com/cloudformation/index.html)._

This guide can be used to deploy 1Password SCIM Bridge as a [stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-whatis-concepts.html#cfn-concepts-stacks) using the [AWS CloudFormation console](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console.html).

The included [AWS CloudFormation template](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stack-templates-overview.html) is a working example that is suitable for use in a production environment. Some common customizations are included for convenience, but it is intentionally minimal for simplicity, to allow any identity provider to connect to its public endpoint, and to facilitate its use as a base for a custom deployment that meets your specific requirements.

This template deploys 1Password SCIM Bridge and the required Redis cache as Fargate tasks within ECS services integrated with AWS Cloud Map for service discovery. A VPC with at least two public subnets is required; these will be created automatically if not provided. Credentials are stored in and provided by AWS Secrets Manager. A public TLS endpoint is provided by Amazon API Gateway. Minimal IAM roles, policy, and security group resources are included for access control and principle of least privelege.

## Prerequisites

- A 1Password account with an active 1Password Business subscription or trial
  > [!TIP]
  > Try 1Password Business **free** for 14 days: <https://start.1password.com/sign-up/business>
- An AWS account with the permissions and available quota to create and manage the described resources

## Before you begin

Consult the [Preparation Guide](/PREPARATION.md) in this repository. Since this CloudFormation template will create all necessary resources, it does not use the CertificateManager component to acquire and manage a TLS certificate. API Gateway provides the TLS endpoint. No DNS records are required.

1. Download the [`op-scim-bridge.yaml`](./op-scim-bridge.yaml) template file from this repository to your computer.
2. Follow the steps in [Automate provisioning in 1Password Business using SCIM](https://support.1password.com/scim/#step-1-set-up-and-deploy-1password-scim-bridge) to generate credentials for your SCIM bridge.
3. Save the `scimsession` credentials file and the associated bearer token as items in your 1Password account.
4. Download the `scimsession` file to your computer.

## Step 1: Upload the stack template file

1. Sign in to AWS and [create a stack](https://console.aws.amazon.com/cloudformation/home#/stacks/create) (if you don't want to click that link, in the CloudFormation console, choose **Create stack** and then **With new resources (standard)**).
2. In the **Prerequisite - Prepare template** section, select **Choose an existing template**.
3. In the **Specify template** section, choose **Upload a template file**.
4. Click **↑ Choose file** and upload the [`op-scim-bridge.yaml`](./op-scim-bridge.yaml) template file from your computer. Click **Next**.

## Step 2: Specify stack details

1. Type `op-scim-bridge` in the **Stack name** field, or choose your own stack name. CloudFormation will use the stack name (or a truncated version where needed) as a prefix when naming the created AWS resources.
2. To use an existing VPC, input its ID in the **VPC ID** field. The stack will create a new VPC with two public subnets and associated resources if this field is empty.
3. A CIDR block must be specified when creating a VPC. If creating a VPC with the stack, use the default value provided or specify your own in the **VPC CIDR** field. This field is ignored when specifying a VPC ID.
4. If specifying an existing VPC, input a comma-separated list of IDs for at least two public subnet IDs in the **Public subnets** field. The subnets must span at least two Avilability Zones. This field is required when using an existing VPC and ignored otherwise.
5. If you are provisioning more than 1,000 users to 1Password, choose the appropriate value for **Provisioning volume**. Choose `high` for up to 5,000 users, or `very-high` for more than 5,000.
6. Open the `scimsession` file from your working directory in your favourite text editor. Select all text in the file and copy it to your clipboard. Paste the contents into the `scimession` field (input will be masked).
7. **If Google Workspace is your identity provider**, [create a service account, key, and API client](https://support.1password.com/scim-google-workspace/#step-1-create-a-google-service-account-key-and-api-client). Save the Google Workspace service account key file to your computer, open the file in a text editor, select all text in the file, and copy it to your clipboard. In the **Workspace configuration** section:
   - Paste the contents of the key file (from your clipboard) into the **Service account key** field (the input will be masked).
   - Input the email address for a Google Workspace administrator to use with the service account in the **Actor** field.
8. Click **Next**.

## Step 3: Configure stack options

1. Click **Add new tag** to add any that you require to all supported resources in the stack.
2. Review the options. Use the provided defaults or your own options as required or preferred. Click **Next**.

## Step 4: Review and create the stack

1. Review the details and edit as necessary.
2. Select **I acknowledge that AWS CloudFormation might create IAM resources**.
3. Click **Submit** to begin deploying the stack.

The console will display the stack status as `ℹ️ CREATE_IN_PROGRESS` during the deployment. The stack is expected to take a few minutes to create (~2–3 minutes when this document was written).

> [!IMPORTANT]
>
> If this is the first time deploying an ECS cluster using your AWS account, CloudFormation may fail to create the
> `AWS::ECS::Cluster` resource (`ECSCluster`) with an error containing:
>
> ```plaintext
> Unable to assume the service linked role. Please verify that the ECS service linked role exists.
> ```
>
> To resolve this issue, when the failed stack finishes rolling back (`ROLLBACK COMPLETE`), click **Delete** to remove
> it, then try to create the stack again. The next attempt will succeed if the service-linked role has been
> successfully created from the prior failed attempt. For more details, see the related issue:
> https://github.com/1Password/scim-examples/issues/356.

## Step 5: Test your SCIM bridge

Your **SCIM bridge URL** is displayed in the **Outputs** tab of the CloudFormation console. Click the link to access the web interface for your SCIM bridge. Sign in using your bearer token to test the connection, view status information, and download logs.

To test the connection and view the same status information in your terminal, you can send an authenticated request to the `/health` endpoint of your SCIM bridge. Replace `mF_9.B5f-4.1JqM` with your bearer token and `https://scim.example.com` with your SCIM bridge URL.

```sh
curl --silent --show-error --request GET --header "Accept: application/json" \
  --header "Authorization: Bearer mF_9.B5f-4.1JqM" \
  https://scim.example.com/health
```

> [!TIP]
> If you saved your bearer token as an item in your 1Password account, you can [use 1Password CLI to supply the bearer token](https://developer.1password.com/docs/cli/secrets-scripts#option-2-use-op-read-to-read-secrets) instead. For example:
>
> ```sh
> # ...
>   --header "Authorization: Bearer $(op read "op://Employee/bearer token/credential")"
> # ...
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

## Step 6: Connect your identity provider

Use your SCIM bridge URL and bearer token to [connect your identity provider to 1Password SCIM Bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

If you are integrating with Google Workspace, sign in to your SCIM bridge URL using your bearer token and [set up provisioning to 1Password](https://support.1password.com/scim-google-workspace/#22-set-up-provisioning-to-1password).

## Maintenance

A quarterly review and maintenance schedule is recommended.

### Update your SCIM bridge

To update to the latest version of 1Password SCIM Bridge, update your stack with a new value for the `SCIMBridgeVersion` parameter. Use the latest template from this repository ([`op-scim-bridge.yaml`](./op-scim-bridge.yaml)) and update the value of "1Password SCIM Bridge version" (the `SCIMBridgeVersion` parameter) to the latest version. Use the existing values for everything else.
