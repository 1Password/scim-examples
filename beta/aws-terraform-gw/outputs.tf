output "settings" {
  description = "Google Workspace Settings"
  value       = aws_secretsmanager_secret.workspace_settings
}

output "credentials" {
  description = "Google Workspace Credentials"
  value       = aws_secretsmanager_secret.workspace_credentials
  sensitive   = true
}