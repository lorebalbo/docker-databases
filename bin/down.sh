#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

show_help() {
    echo "Usage: down.sh [OPTIONS]"
    echo "Options:"
    echo "  -h, --help      Display this help message and exit"
    echo "  -v, --volumes   Remove named volumes declared in the 'volumes' section of the Compose file"
    echo "  --rmi           Remove images used by services"
    echo "  -n, --networks  Remove the network specified in the DOCKER_NETWORK_NAME environment variable"
    echo "  -f, --file      Specify a docker-compose file to use"
    echo ""
    echo "Example: down.sh --volumes --networks -f ./custom-compose.yml"
    exit 0
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

# Reset positional parameters for proper argument parsing
set -- "${ORIGINAL_ARGS[@]}"

# Initialize variables for options
volumes_flag=""
rmi_flag=""
network_flag=""
compose_files=""
compose_command="docker compose"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--volumes)
            volumes_flag="-v"
            shift
            ;;
        --rmi)
            rmi_flag="--rmi"
            shift
            ;;
        -n|--networks)
            network_flag="true"
            shift
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
        *)
            echo "Error: Invalid argument $1"
            echo "Use -h or --help to see available options."
            exit 1
            ;;
    esac
    shift
done

# Get project name from env variable or use current directory name as fallback
if [[ -n "$DOCKER_PROJECT_NAME" ]]; then
    project_name="$DOCKER_PROJECT_NAME"
else
    # Extract the current directory name
    project_name='composes'
fi

# Add project name to compose command
compose_command+=" -p $project_name"

# Run docker compose down with the appropriate flags
$compose_command down $volumes_flag $rmi_flag

# Remove the network if -n or --networks is passed
if [ "$network_flag" == "true" ]; then
    if [ -z "$DOCKER_NETWORK_NAME" ]; then
        echo "Error: DOCKER_NETWORK_NAME is not set in the environment."
        exit 1
    fi
    docker network rm "$DOCKER_NETWORK_NAME" || echo "Network $DOCKER_NETWORK_NAME does not exist."
fi
