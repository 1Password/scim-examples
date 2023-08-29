output "secrets" {
  description = "Google Workspace secret references to append to container definition environment."
  value       = local.secrets
}
