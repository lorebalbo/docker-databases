#!/bin/bash

set -e

source .env

# Display help message
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

# Initialize variables for options
volumes_flag=""
rmi_flag=""
network_flag=""
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
        *)
            echo "Error: Invalid argument $1"
            echo "Use -h or --help to see available options."
            exit 1
            ;;
    esac
done

# Get project name from env variable or use current directory name as fallback
if [[ -n "$DOCKER_PROJECT_NAME" ]]; then
    project_name="$DOCKER_PROJECT_NAME"
else
    # Extract the current directory name
    project_name=$(basename "$(pwd)")
fi

# Add project name to compose command
compose_command+=" -p $project_name"

# Run docker compose down with the appropriate flags
# $compose_command down $volumes_flag $rmi_flag
echo "$compose_command down $volumes_flag $rmi_flag"

# Remove the network if -n or --networks is passed
if [ "$network_flag" == "true" ]; then
    if [ -z "$DOCKER_NETWORK_NAME" ]; then
        echo "Error: DOCKER_NETWORK_NAME is not set in the environment."
        exit 1
    fi
    # docker network rm "$DOCKER_NETWORK_NAME" || echo "Network $DOCKER_NETWORK_NAME does not exist."
fi
