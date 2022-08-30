data "aws_iam_policy_document" "workspace_config" {
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

# Create the iam_policy that points to the policy document above. 
resource "aws_iam_policy" "workspace" {
  name_prefix = var.name_prefix
  policy = data.aws_iam_policy_document.workspace_config
}

# refactored to point to the assume_role_policy in main.tf (I hope)
resource "aws_iam_role" "workspace_config" {
  name_prefix        = var.name_prefix
  assume_role_policy = local.assume_role_policy.json

  tags = var.tags
}

# attach aws_iam_role.workspace_config to the aws_iam_policy.workspace policy
resource "aws_iam_role_policy_attachment" "workspace" {
  role = aws_iam_role.workspace_config
  policy_arn = aws_iam_policy.workspace
}

resource "aws_secretsmanager_secret" "workspace_settings" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "workspace_settings" {
  secret_id     = aws_secretsmanager_secret.workspace_settings.id
  secret_string = fileexists("${path.root}/workspace-settings.json") ? filebase64("${path.root}/workspace-settings.json") : ""
}

resource "aws_secretsmanager_secret" "workspace_credentials" {
  name_prefix = var.name_prefix

  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "workspace_credentials" {
  secret_id     = aws_secretsmanager_secret.workspace_credentials.id
  secret_string = fileexists("${path.root}/workspace-credentials.json") ? filebase64("${path.root}/workspace-credentials.json") : ""
}
