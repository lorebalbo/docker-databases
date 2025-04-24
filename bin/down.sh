#!/bin/bash

set -e

# ------------------------------------------------------------------------------
# Variables

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

DRYRUN=0

CUSTOM_ENV_FILE=""
NETWORK=0

COMPOSE_COMMAND="docker compose"

# ------------------------------------------------------------------------------
# Utils

# Help function to display usage information
display_help() {
    echo "Usage: down.sh [options] [-- additional docker-compose arguments]"
    echo "Options:"
    echo "  -h, --help      Display this help message and exit"
    echo "  --dry-run       Show the command that would be run without executing it"
    echo "  -n, --networks  Remove the network specified in the DOCKER_NETWORK_NAME environment variable"
    echo "  -e, --env-file  Specify a custom environment file to use"
    echo ""
    echo "Additional arguments after -- will be passed directly to docker compose"
    echo ""
    echo "Examples:"
    echo "  down.sh -e ./custom.env"
    echo "  down.sh -- --rmi all"
    echo "  down.sh -- --volumes"
}

# ------------------------------------------------------------------------------
# Parse arguments

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            display_help
            exit 0
            ;;
        --dry-run)
            DRYRUN=1
            ;;
        -n|--networks)
            NETWORK=1
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
if [[ -n "$custom_env_file" ]]; then
    source "$custom_env_file"
    ENV_FILE="$custom_env_file"
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

# Down
COMPOSE_COMMAND+=" down"

# Append any extra arguments
if [[ -n "$EXTRA_ARGS" ]]; then
    COMPOSE_COMMAND+=" $EXTRA_ARGS"
fi

# ------------------------------------------------------------------------------
# Run

# Run the docker compose command
if [[ $DRYRUN -eq 1 ]]; then
    echo "Running docker compose command: $COMPOSE_COMMAND"
else
    eval "$COMPOSE_COMMAND"
fi

# Remove the network if -n or --networks is passed
if [ "$NETWORK" -eq 1 ]; then
    if [ -z "$DOCKER_NETWORK_NAME" ]; then
        echo "Error: DOCKER_NETWORK_NAME is not set in the environment."
        exit 1
    fi

    if [[ $DRYRUN -eq 1 ]]; then
        echo "Running docker network command: docker network rm $DOCKER_NETWORK_NAME"
    else
        echo "Removing network $DOCKER_NETWORK_NAME"
        docker network rm "$DOCKER_NETWORK_NAME" || echo "Network $DOCKER_NETWORK_NAME does not exist."
    fi
fi