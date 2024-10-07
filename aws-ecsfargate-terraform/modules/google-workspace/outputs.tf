output "container_definitions" {
  description = "Merged configuration for connecting to Google Workspace."
  value = [for container in var.container_definitions :
    merge(container,
      {
        command     = [join(" && ", [container.command[0], local.command])]
        environment = concat(container.environment, local.environment)
      }
    ) if container.name == "mount-secrets"
  ]
}
