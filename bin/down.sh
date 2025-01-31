#!/bin/bash

if [[ "$1" == "-v" || "$1" == "--volumes" ]]; then
    docker compose down -v
else
    docker compose down
fi
