locals {
  # Create a file set for expected service account key file name
  workspace_credentials_file = fileset(
    path.root, # Root module directory
    "*.json"   # Any file with `.json` extension
  )

  # Conditions for a valid service account file
  any_json_file = length(data.local_sensitive_file.workspace_credentials_file) != 0      # At least one JSON file
  one_json_file = length(data.local_sensitive_file.workspace_credentials_file) <= 1      # No more than one JSON file
  valid_service_account = local.any_json_file && local.one_json_file ? (                 # Valid service account file
    keys(jsondecode(data.local_sensitive_file.workspace_credentials_file[0].content)) == # JSON file keys
    keys(jsondecode(file("${path.module}/template/service_account_key.json")))           # template file keys
  ) : false
}

data "local_sensitive_file" "workspace_credentials_file" {
  count = length(local.workspace_credentials_file)

  filename = tolist(local.workspace_credentials_file)[count.index]
}

resource "aws_secretsmanager_secret" "workspace_credentials" {
  name_prefix             = var.name_prefix
  description             = "Google Cloud service account key for connecting Workspace to 1Password SCIM Bridge."
  recovery_window_in_days = 0

  lifecycle {
    precondition {
      condition = local.any_json_file
      error_message = join("\n\n", [
        "A service account key file was not found.",
        "Save the Google Cloud service account key file to the working directory:", abspath(path.root)
      ])
    }

    precondition {
      condition = local.one_json_file
      error_message = join("\n\n", [
        "Multiple JSON files were found:",
        join("\n", [
          for file in data.local_sensitive_file.workspace_credentials_file[*].filename : " - ${abspath(file)}"
        ]),
        "Save the Google Cloud service account key file to the working directory:", abspath(path.root),
        "Remove any other `.json` files from the directory."
      ])
    }
  }
}

resource "aws_secretsmanager_secret_version" "workspace_credentials" {
  count = length(data.local_sensitive_file.workspace_credentials_file)

  secret_id     = aws_secretsmanager_secret.workspace_credentials.id
  secret_string = data.local_sensitive_file.workspace_credentials_file[count.index].content

  lifecycle {
    precondition {
      condition = local.valid_service_account
      error_message = join("\n\n", [
        "Invalid service account key file.",
        "The detected JSON file does not match the expected structure of a Google Cloud service account key:",
        abspath(data.local_sensitive_file.workspace_credentials_file[count.index].filename),
        "Save the correct service account key file to the working directory:", path.cwd,
        "Remove any other `.json` files from this directory."
      ])
    }
  }
}

resource "aws_secretsmanager_secret" "workspace_settings" {
  name_prefix             = var.name_prefix
  description             = "Configuration for connecting 1Password SCIM Bridge."
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "workspace_settings" {
  secret_id = aws_secretsmanager_secret.workspace_settings.id
  secret_string = jsonencode({
    actor         = var.actor
    bridgeAddress = var.bridgeAddress
  })
}

data "aws_iam_policy_document" "read_gw_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.workspace_settings.arn,
      aws_secretsmanager_secret.workspace_credentials.arn,
    ]
  }
}

resource "aws_iam_policy" "read_gw_secrets" {
  name_prefix = var.name_prefix
  policy      = data.aws_iam_policy_document.read_gw_secrets.json
  description = "Allow reading the AWS secrets for connecting Google Workspace to 1Password SCIM Bridge."
}

resource "aws_iam_role_policy_attachment" "attach_gw_policy" {
  role       = var.iam_role
  policy_arn = aws_iam_policy.read_gw_secrets.arn
}

locals {
  # Configuration parameters for mounting Google Workspace secrets
  secrets_config = {
    # Google Cloud service account key file
    workspace_credentials = {
      env_var  = "WORKSPACE_CREDENTIALS_ARN"                         # name to reference via AWS CLI
      arn      = aws_secretsmanager_secret.workspace_credentials.arn # AWS secret ARN
      filename = "workspace-credentials.json"                        # file name to write in volume
    }
    # Google Workspace settings
    workspace_settings = {
      env_var  = "WORKSPACE_SETTINGS_ARN"                         # name to reference via AWS CLI
      arn      = aws_secretsmanager_secret.workspace_settings.arn # AWS secret ARN
      filename = "workspace-settings.json"                        # File name to write in volume
    }
  }

  # AWS CLI commands to write Google Workspace secrets to secrets volume
  command = join(" && ", [                           # chain commands
    for secret in local.secrets_config : join(" ", [ # for each of the defined configs
      "aws secretsmanager get-secret-value",         # get the contents of an AWS secret
      format("--secret-id $%s", secret.env_var),     # ARN of the secret (`format` function to handle `$` char)
      "--query SecretString", "--output text",       # get unencrypted string value in plain text output
      "> ${secret.filename}"                         # write output to volume
    ])
  ])

  # Environment variables for secret ARNs
  environment = [
    for secret in local.secrets_config : {
      name  = secret.env_var
      value = secret.arn
    }
  ]
}
