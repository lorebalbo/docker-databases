#!/bin/bash

set -e

# Display help information
display_help() {
    echo "Usage: up.sh [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Display this help message and exit"
    echo "  -e, --env-file  Specify an environment file to use"
    echo "  -f, --file      Specify a docker-compose file to use"
    echo ""
    echo "Example: up.sh -f ./custom-compose.yml -e ./custom.env"
}

source .env

# Create the Docker network if it doesn't exist
if ! docker network ls --filter name=^$DOCKER_NETWORK_NAME$ --format "{{.Name}}" | grep -w $DOCKER_NETWORK_NAME > /dev/null; then
    docker network create ${DOCKER_NETWORK_NAME:-devnet}
fi

# Function to check if a service is enabled
is_service_enabled() {
    local service_enabled_var="${1}_ENABLED"
    local service_enabled_value="${!service_enabled_var}"
    [[ "$service_enabled_value" != "false" ]]
}

compose_command="docker compose"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_help
            exit 0
            ;;
        -e|--env-file)
            if [[ -n "$2" ]]; then
                source "$2"
                compose_command+=" --env-file $2"
                shift
            else
                echo "Error: --env-file requires a file path argument."
                exit 1
            fi
            ;;
        -f|--file)
            if [[ -n "$2" ]]; then
                compose_command+=" -f $2"
                shift
            else
                echo "Error: --file requires a file path argument."
                exit 1
            fi
            ;;
        *)
            echo "Error: Invalid argument $1"
            echo "Use -h or --help to see available options."
            exit 1
            ;;
    esac
    shift
done

# Find all *_ENABLED variables and conditionally add services to the command
for var in $(compgen -A variable | grep '_ENABLED$'); do
    service="${var%_ENABLED}"
    if is_service_enabled "$service"; then
        compose_command+=" -f composes/docker-compose-${service,,}.yml"
    fi
done

compose_command+=" up -d"

# if the DOCKER_PROJECT_NAME variable is set, add -p $DOCKER_PROJECT_NAME to the command
if [[ -n "$DOCKER_PROJECT_NAME" ]]; then
    compose_command+=" -p $DOCKER_PROJECT_NAME"
fi

# Run the docker compose command
echo "Running docker compose command: $compose_command"
eval "$compose_command"