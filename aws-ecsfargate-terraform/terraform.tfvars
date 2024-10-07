# --- Required variables ---

# The domain name for your 1Password SCIM Bridge deployment.
domain_name = "scim.example.com"

# The image tag for the 1Password SCIM Bridge to use for the deployment.
scim_bridge_version = "v2.9.6"

# --- Optional variables ---

# The AWS region to use with the provider. If not set, use the region from the profile or environment.
# aws_region = "us-east-1"

# An AWS profile name to use with the provider. If not set, use the "default" profile or environment.
# aws_profile = "saml"

# The ID of an existing VPC to use. If not set, a VPC is created.
# vpc_id = "vpc-123"

# A list of at least two public subnets in the VPC that span at least two availability zones. If a VPC is not
# specified, this value is ignored. Required if specifying a VPC.
# public_subnets = [
#   "subnet-1",
#   "subnet-2"
# ]

# A common name prefix to apply to supported resources. If not set, supported resources are named by Terraform.
# name_prefix = "example-prefix"

# Tags to add to all supported resources.
# tags = {
# #   key = "value"
# }

# Whether to use an existing wildcard certificate from AWS Certificate Manager. If not set, a certificate is created.
# wildcard_cert = true

# Whether required DNS records should be created using Amazon Route 53. If not set, records are created suing Route 53.
# using_route53 = false

# The CloudWatch Logs retention period. If not set, logs are stored indefinitely.
# log_retention_days = 30

# --- Connecting to Google Workspace --- 

# The Workspace adminstrator email delegated by the Google Cloud service account. Required to connect to Workspace. If
# not set, SCIM bridge will not be configured to connect to Workspace.
# google_workspace_actor = "administrator.email@example.com"
