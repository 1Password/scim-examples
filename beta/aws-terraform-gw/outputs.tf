output "settings" {
  description = "Google Workspace "
  value       = aws_secretsmanager_secret.workspace_settings
}

output "credentials" {
  value = aws_secretsmanager_secret.workspace_credentials
}