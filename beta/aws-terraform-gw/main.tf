data "aws_iam_policy_document" "workspace_config" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.workspace_credentials.arn,
      aws_secretsmanager_secret.workspace_settings.arn,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "creds" {
  secret_id     = aws_secretsmanager_secret.scimsession.id
  secret_string = base64encode(file("${path.module}/scimsession"))
}


resource "aws_secretsmanager_secret" "workspace_settings" {
  name_prefix = local.name_prefix

  recovery_window_in_days = 0

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "workspace_settings" {
  secret_id     = aws_secretsmanager_secret.workspace_settings.id
  secret_string = filebase64("../beta/workspace-settings.json")
}

resource "aws_secretsmanager_secret" "workspace_credentials" {
  name_prefix             = local.name_prefix
  recovery_window_in_days = 0

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "workspace_credentials" {
  secret_id     = aws_secretsmanager_secret.workspace_credentials.id
  secret_string = filebas64("../beta/workspace-credentials.json")
}
