#!/bin/bash

set -e

# ------------------------------------------------------------------------------
# Variables

DEBUG=0

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

CUSTOM_ENV_FILE=""
FILE=""

COMPOSE_COMMAND="docker compose"
EXTRA_ARGS=""

# ------------------------------------------------------------------------------
# Utils

# Help function to display usage information
display_help() {
    echo "Usage: up.sh [options] [-- additional docker-compose arguments]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Display this help message and exit"
    echo "  --debug         Enable debug mode"
    echo "  -e, --env-file  Specify an environment file to use"
    echo "  -f, --file      Specify a docker-compose file to use"
    echo ""
    echo "Additional arguments after -- will be passed directly to docker compose"
    echo ""
    echo "Examples:"
    echo "  up.sh -f ./custom-compose.yml -e ./custom.env"
    echo "  up.sh -- --no-deps service_name"
    echo "  up.sh -- --build --force-recreate"
}

# Check if a service is enabled
is_service_enabled() {
    local service_enabled_var="${1}_ENABLED"
    local service_enabled_value="${!service_enabled_var}"
    [[ "$service_enabled_value" != "false" ]]
}

# ------------------------------------------------------------------------------
# Parse arguments

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_help
            exit 0
            ;;
        --debug)
            DEBUG=1
            ;;
        -f|--file)
            if [[ -n "$2" ]]; then
                FILE=" -f $2"
                shift
            else
                echo "Error: --file requires a file path argument."
                exit 1
            fi
            ;;
        -e|--env-file)
            if [[ -n "$2" ]]; then
                CUSTOM_ENV_FILE="$2"
                shift
            else
                echo "Error: --env-file requires a file path argument."
                exit 1
            fi
            ;;
        --)
            # Everything after -- is passed to docker compose
            shift
            EXTRA_ARGS="$*"
            break
            ;;
        *)
            echo "Error: Invalid argument $1"
            echo "Use -h or --help to see available options."
            display_help
            exit 1
            ;;
    esac
    shift
done

# ------------------------------------------------------------------------------
# Setup the environment

# Use custom .env if provided, otherwise default (.env in root of docker-databases)
if [[ -n "$CUSTOM_ENV_FILE" ]]; then
    source "$CUSTOM_ENV_FILE"
    ENV_FILE="$CUSTOM_ENV_FILE"
elif [[ -f "$PROJECT_DIR/.env" ]]; then
    source "$PROJECT_DIR/.env"
    ENV_FILE="$PROJECT_DIR/.env"
else
    echo "Warning: No .env file found in $PROJECT_DIR"
fi

# ------------------------------------------------------------------------------
# Build compose

# Add compose name
# Use DOCKER_COMPOSE_NAME variable is set, if not, use use the name of the $PROJECT_DIR
if [[ -n "$DOCKER_PROJECT_NAME" ]]; then
    COMPOSE_COMMAND+=" -p $DOCKER_PROJECT_NAME"
else
    project_name=$(basename "$PROJECT_DIR")
    COMPOSE_COMMAND+=" -p $project_name"
fi

# Add additional docker compose files if specified
if [[ -n "$FILE" ]]; then
    COMPOSE_COMMAND+=" -f $FILE"
fi

# Find all *_ENABLED variables and conditionally add services to the command
for var in $(compgen -A variable | grep '_ENABLED$'); do
    service="${var%_ENABLED}"
    if is_service_enabled "$service"; then
        COMPOSE_COMMAND+=" -f $PROJECT_DIR/composes/docker-compose-${service,,}.yml"
    fi
done

# Add env file
if [[ -n "$ENV_FILE" ]]; then
    COMPOSE_COMMAND+=" --env-file $ENV_FILE"
fi

# Run and detach
COMPOSE_COMMAND+=" up"

# Append any extra arguments
if [[ -n "$EXTRA_ARGS" ]]; then
    COMPOSE_COMMAND+=" $EXTRA_ARGS"
fi

# ------------------------------------------------------------------------------
# Network

# Create the Docker network if it doesn't exist so that all containers can communicate
if ! docker network ls --filter name=^$DOCKER_NETWORK_NAME$ --format "{{.Name}}" | grep -w $DOCKER_NETWORK_NAME > /dev/null; then
    docker network create ${DOCKER_NETWORK_NAME:-devnet}
fi

# ------------------------------------------------------------------------------
# Run

# Run the docker compose command
if [[ $DEBUG -eq 1 ]]; then
    echo "Running docker compose command: $COMPOSE_COMMAND"
else
    eval "$COMPOSE_COMMAND"
fi