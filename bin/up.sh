#!/bin/bash

set -e

source .env

# Function to check if a service is enabled
is_service_enabled() {
    local service_enabled_var="${1}_ENABLED"
    local service_enabled_value="${!service_enabled_var}"
    [[ "$service_enabled_value" != "false" ]]
}

compose_command="docker compose"

# Check if the -e or --env-file argument is passed
if [[ "$1" == "-e" || "$1" == "--env-file" ]]; then
    if [[ -n "$2" ]]; then
        source "$2"
        compose_command+=" --env-file $2"
    else
        echo "Error: --env-file requires a file path argument."
        exit 1
    fi
fi

compose_command+=" up -d"

# Find all *_ENABLED variables and conditionally add services to the command
for var in $(compgen -A variable | grep '_ENABLED$'); do
    service="${var%_ENABLED}"
    if is_service_enabled "$service"; then
        compose_command+=" ${service,,}"
    fi
done

# Run the docker compose command
# echo "Running docker compose command: $compose_command"
eval "$compose_command"