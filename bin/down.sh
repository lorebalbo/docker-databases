#!/bin/bash

set -e

# Display help message if invalid arguments are passed
show_help() {
    echo "Usage: down.sh [OPTIONS]"
    echo "Options:"
    echo "  -v, --volumes   Remove named volumes declared in the 'volumes' section of the Compose file"
    echo "  --rmi           Remove images used by services"
    exit 1
}

# Initialize variables for options
volumes_flag=""
rmi_flag=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        -v|--volumes)
            volumes_flag="-v"
            ;;
        --rmi)
            rmi_flag="--rmi"
            ;;
        *)
            show_help
            ;;
    esac
done

# Run docker compose down with the appropriate flags
docker compose down $volumes_flag $rmi_flag
# echo "docker compose down $volumes_flag $rmi_flag"
