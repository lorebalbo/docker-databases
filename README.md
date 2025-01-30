# Docker Compose Databases

This repository provides a Docker Compose setup for running PostgreSQL, MongoDB, and PgAdmin. It allows you to easily spin up these database services with predefined configurations using environment variables.

## Configuration

The services can be configured using the `.env` file. An example configuration is provided in the `.env.example` file. You can set versions, ports, usernames, passwords, and other settings through this file.

## Usage

1. Copy the `.env.example` file to `.env` and adjust the settings as needed.
2. Run `docker-compose up -d` to start the services.
3. Access PgAdmin at `http://localhost:8080` (or the port you configured).

## Operations

You can perform various operations using the `docker compose -p dockerdb` command followed by the operation, such as `ps`, `stop`, `start`, etc. That way is not required to be in the same directory as the `docker-compose.yml` file.

## Environment Files

It is possible to have multiple environment files and run the compose with a specific env file using the `--env-file` option. For example:
- `docker compose --env-file .env.production up -d` to use the `.env.production` file.

## Volumes

The data for PostgreSQL and MongoDB is persisted using Docker volumes:
- `postgres_volume_local`
- `mongo_volume_local`

## Networks

All services are connected through a Docker network named `db-network`.
