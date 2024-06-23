#!/bin/bash

log_error() {
  echo "****************************"
  echo "ERROR: $1"
  echo "****************************" >&2
}

log_info() {
  echo "****************************"
  echo "INFO: $1"
  echo "****************************"
}

log_details() {
  echo "$1"
}

# Function to check if a container exists
container_exists() {
  podman ps -a --format "{{.Names}}" | grep -wq "$1"
}

# Function to check if a secret exists
secret_exists() {
  podman secret ls --format "{{.Name}}" | grep -wq "$1"
}

# Function to stop and remove containers
cleanup_containers() {
  log_info "Stopping and removing all containers in the op-scim network."

  local containers=("scim" "redis")
  for container in "${containers[@]}"; do
    if container_exists "$container"; then
      log_details "- Stopping container $container"
      if podman stop -t 10 "$container" >/dev/null 2>&1; then
        log_details "- Removing container $container"
        if podman rm "$container" >/dev/null 2>&1; then
          log_details "- Container $container removed."
        else
          log_error "Failed to remove container $container"
        fi
      else
        log_error "Failed to stop container $container"
      fi
    else
      log_details "- Container $container does not exist. Skipping stop and removal."
    fi
  done
}

# Function to remove secrets
cleanup_secrets() {
  log_info "Removing secrets."
  local secrets=("scimsession" "op-tls-cert" "op-tls-key" "workspace-credentials" "workspace-settings")
  for secret in "${secrets[@]}"; do
    if secret_exists "$secret"; then
      log_details "- Removing secret $secret"
      if podman secret rm "$secret" >/dev/null 2>&1; then
        log_details "- Secret $secret removed."
      else
        log_error "Failed to remove secret $secret"
      fi
    fi
  done
}

# Function to remove networks
cleanup_networks() {
  log_info "Removing networks."
  if podman network exists op-scim; then
    log_details "- Removing network op-scim"
    if podman network rm op-scim >/dev/null 2>&1; then
      log_details "- Network op-scim removed."
    else
      log_error "Failed to remove network op-scim"
    fi
  else
    log_details "- Network op-scim not found. Skipping network removal."
  fi
}

# Main script execution
log_info "Starting teardown process."
cleanup_containers
cleanup_secrets
cleanup_networks

echo -e "\n"
echo "****************************"
log_details "Teardown complete."
echo "****************************"
