# Construct an IAM policy document to allow reading secrets for Google Workspace
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

# Create a policy from the document
resource "aws_iam_policy" "read_gw_secrets" {
  name_prefix = var.name_prefix
  policy      = data.aws_iam_policy_document.read_gw_secrets.json
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_gw_policy" {
  role       = var.iam_role.name
  policy_arn = aws_iam_policy.read_gw_secrets.arn
}

resource "aws_secretsmanager_secret" "workspace_settings" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "workspace_settings" {
  secret_id = aws_secretsmanager_secret.workspace_settings.id
  secret_string = !var.enabled ? null : jsonencode({
    actor         = var.actor
    bridgeAddress = var.bridgeAddress
  })
}

resource "aws_secretsmanager_secret" "workspace_credentials" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "workspace_credentials" {
  secret_id     = aws_secretsmanager_secret.workspace_credentials.id
  secret_string = !var.enabled ? null : file("${path.root}/workspace-credentials.json")
}
