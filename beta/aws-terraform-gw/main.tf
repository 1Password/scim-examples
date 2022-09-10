locals {
  # Define secret reference list
  secrets = [
    {
      name      = "OP_WORKSPACE_CREDENTIALS"
      valueFrom = aws_secretsmanager_secret.workspace_credentials.arn
    },
    {
      name      = "OP_WORKSPACE_SETTINGS",
      valueFrom = aws_secretsmanager_secret.workspace_settings.arn,
    },
  ]
}

# Construct an IAM policy document
data "aws_iam_policy_document" "this" {
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

# Create a policy from the document and attach it to the IAM role
resource "aws_iam_role_policy" "this" {
  name_prefix = var.name_prefix
  policy      = data.aws_iam_policy_document.this.json
  role        = var.iam_role.name
}

resource "aws_secretsmanager_secret" "workspace_settings" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "workspace_settings" {
  secret_id     = aws_secretsmanager_secret.workspace_settings.id
  secret_string = var.enabled ? filebase64("${path.root}/workspace-settings.json") : null
}

resource "aws_secretsmanager_secret" "workspace_credentials" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "workspace_credentials" {
  secret_id     = aws_secretsmanager_secret.workspace_credentials.id
  secret_string = var.enabled ? filebase64("${path.root}/workspace-credentials.json") : null
}
