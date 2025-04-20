#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

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

# Parse arguments and check if env-file is specified
custom_env_file=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--env-file)
            if [[ -n "$2" ]]; then
                custom_env_file="$2"
                break
            fi
            ;;
    esac
    shift
done

# Reset positional parameters
ORIGINAL_ARGS=("$@")
set -- "${ORIGINAL_ARGS[@]}"

# Set up the environment file - use custom if provided, otherwise default
if [[ -n "$custom_env_file" ]]; then
    source "$custom_env_file"
    ENV_FILE="$custom_env_file"
elif [[ -f "$PROJECT_DIR/.env" ]]; then
    source "$PROJECT_DIR/.env"
    ENV_FILE="$PROJECT_DIR/.env"
else
    echo "Warning: No .env file found in $PROJECT_DIR"
fi

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

# Add env-file to compose command by default if we found an .env file
if [[ -n "$ENV_FILE" ]]; then
    compose_command+=" --env-file $ENV_FILE"
fi

# Reset positional parameters for proper argument parsing
set -- "${ORIGINAL_ARGS[@]}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_help
            exit 0
            ;;
        -e|--env-file)
            if [[ -n "$2" ]]; then
                # Already handled above, just skip
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
        compose_command+=" -f $PROJECT_DIR/composes/docker-compose-${service,,}.yml"
    fi
done

# if the DOCKER_PROJECT_NAME variable is set, add -p $DOCKER_PROJECT_NAME to the command
if [[ -n "$DOCKER_PROJECT_NAME" ]]; then
    compose_command+=" -p $DOCKER_PROJECT_NAME"
fi

compose_command+=" up -d"

# Run the docker compose command
echo "Running docker compose command: $compose_command"
eval "$compose_command"