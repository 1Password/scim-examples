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

resource "aws_iam_role_policy" "workspace_config" {
  name_prefix = var.name_prefix
  role        = aws_iam_role.workspace_config.id
  policy      = data.aws_iam_policy_document.workspace_config.json
}

resource "aws_iam_role" "workspace_config" {
  name_prefix        = var.name_prefix
  assume_role_policy = data.aws_iam_policy_document.workspace_config.json

  tags = var.tags
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
