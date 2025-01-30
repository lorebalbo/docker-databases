#!/bin/bash

# Check if the -e or --env-file argument is passed
if [[ "$1" == "-e" || "$1" == "--env-file" ]]; then
    if [[ -n "$2" ]]; then
        docker compose --env-file "$2" up -d
    else
        echo "Error: --env-file requires a file path argument."
        exit 1
    fi
else
    docker compose up -d
fi

