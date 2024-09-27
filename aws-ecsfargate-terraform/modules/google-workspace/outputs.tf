output "container_definitions" {
  description = "Modified task definition container definitions for connecting to Google Workspace."
  value = [
    var.container_definitions[0], # SCIM bridge container
    var.container_definitions[1], # Redis container
    merge(
      var.container_definitions[2], # Secret mounting sidecar container
      {
        # Append Google Workspace environment variables
        environment = concat(
          var.container_definitions[2].environment,
          [
            {
              name  = "WORKSPACE_CREDENTIALS_ARN"
              value = aws_secretsmanager_secret.workspace_credentials.arn
            },
            {
              name  = "WORKSPACE_SETTINGS_ARN",
              value = aws_secretsmanager_secret.workspace_settings.arn,
            },
          ]
        )
      },
      {
        # Prepend container command
        command = [join(" ", [
          var.container_definitions[2].command[0],
          "&&",
          "aws secretsmanager get-secret-value",
          "--secret-id $WORKSPACE_CREDENTIALS_ARN --query SecretString --output text > workspace-credentials.json",
          "&&",
          "aws secretsmanager get-secret-value",
          "--secret-id $WORKSPACE_SETTINGS_ARN --query SecretString --output text > workspace-settings.json"
        ])]
      }
    )
  ]
}
