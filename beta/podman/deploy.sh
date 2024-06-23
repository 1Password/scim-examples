#!/bin/bash

log_error() {
  echo "****************************"
  echo "ERROR: $1"
  echo "****************************" >&2
}

# Function to create a secret if it doesn't already exist
create_or_update_secret() {
  local secret_name=$1
  local secret_file=$2
  podman secret rm "$secret_name" 2>/dev/null
  if ! podman secret create "$secret_name" "$secret_file"; then
    log_error "Failed to create secret $secret_name from file $secret_file"
    exit 1
  fi
}

# Function to create the secrets
create_secrets() {
  echo "****************************"
  echo "Creating secrets."
  echo "****************************"
  create_or_update_secret scimsession ./scimsession

  if [ "$CUSTOM_TLS" = true ]; then
    echo "****************************"
    echo "Creating TLS secrets."
    echo "****************************"
    create_or_update_secret op-tls-cert ./cert.pem
    create_or_update_secret op-tls-key ./key.pem
  fi

  if [ "$EXTRA_SECRETS" = true ]; then
    echo "****************************"
    echo "Creating extra secrets for workspace."
    echo "****************************"
    create_or_update_secret workspace-credentials ./workspace-credentials.json
    create_or_update_secret workspace-settings ./workspace-settings.json
  fi

  # Check for additional secrets in the specified compose files
  for FILE in "${ADDITIONAL_FILES[@]}"; do
    if grep -q "workspace-credentials" "$FILE"; then
      echo "****************************"
      echo "Creating workspace-credentials secret from $FILE."
      echo "****************************"
      create_or_update_secret workspace-credentials ./workspace-credentials.json
    fi
    if grep -q "workspace-settings" "$FILE"; then
      echo "****************************"
      echo "Creating workspace-settings secret from $FILE."
      echo "****************************"
      create_or_update_secret workspace-settings ./workspace-settings.json
    fi
  done
}

# Function to deploy the services
deploy_services() {
  echo "****************************"
  echo "Deploying services."
  echo "****************************"
  COMPOSE_FILES="-f podman.template.yaml"
  if [ "$CUSTOM_TLS" = true ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f podman.custom-tls.yaml"
  fi
  if [ "$EXTRA_SECRETS" = true ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f compose.gw.yaml"
  fi
  for FILE in "${ADDITIONAL_FILES[@]}"; do
    COMPOSE_FILES="$COMPOSE_FILES -f $FILE"
  done
  if ! podman-compose $COMPOSE_FILES up -d; then
    log_error "Failed to deploy services with podman-compose"
    exit 1
  fi
}

# Parse arguments
EXTRA_SECRETS=false
CUSTOM_TLS=false
ADDITIONAL_FILES=()
while [ "$1" != "" ]; do
  case $1 in
    --file )
      shift
      if [ "$1" = "podman.custom-tls.yaml" ]; then
        CUSTOM_TLS=true
      elif [ "$1" = "compose.gw.yaml" ]; then
        EXTRA_SECRETS=true
      else
        ADDITIONAL_FILES+=("$1")
      fi
      ;;
    * )
      log_error "Invalid option: $1"
      exit 1
      ;;
  esac
  shift
done

# Main script execution
echo "****************************"
echo "Setting vm.overcommit_memory."
echo "****************************"
if ! sudo sysctl vm.overcommit_memory=1; then
  log_error "Failed to set vm.overcommit_memory"
  exit 1
fi

create_secrets
deploy_services

echo "****************************"
echo "Fetching logs from the scim container."
echo "****************************"
if podman ps --format "{{.Names}}" | grep -q "^scim$"; then
  podman logs --tail 50 scim || log_error "Failed to fetch logs from the scim container"
else
  log_error "scim container is not running or not found."
fi

echo -e "\n"
echo "****************************"
echo "Deployment complete."
echo "****************************"
