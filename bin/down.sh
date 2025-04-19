#!/bin/bash

set -e

source .env

# Display help message if invalid arguments are passed
show_help() {
    echo "Usage: down.sh [OPTIONS]"
    echo "Options:"
    echo "  -v, --volumes   Remove named volumes declared in the 'volumes' section of the Compose file"
    echo "  --rmi           Remove images used by services"
    echo "  -n, --networks  Remove the network specified in the DOCKER_NETWORK_NAME environment variable"
    exit 1
}

# Initialize variables for options
volumes_flag=""
rmi_flag=""
network_flag=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        -v|--volumes)
            volumes_flag="-v"
            ;;
        --rmi)
            rmi_flag="--rmi"
            ;;
        -n|--networks)
            network_flag="true"
            ;;
        *)
            show_help
            ;;
    esac
    shift
done

# Run docker compose down with the appropriate flags
docker compose down $volumes_flag $rmi_flag

# Remove the network if -n or --networks is passed
if [ "$network_flag" == "true" ]; then
    if [ -z "$DOCKER_NETWORK_NAME" ]; then
        echo "Error: DOCKER_NETWORK_NAME is not set in the environment."
        exit 1
    fi
    docker network rm "$DOCKER_NETWORK_NAME" || echo "Network $DOCKER_NETWORK_NAME does not exist."
fi
