# Docker Compose Databases

This project sets up PostgreSQL, MongoDB, and pgAdmin using Docker Compose.

## Usage

### Start the services

To start the services, run:

```bash
./bin/up.sh
```

To start the services with a specific environment file, run:

```bash
./bin/up.sh -e path/to/your/.env
```

### Stop the services

To stop the services and remove the volumes, run:

```bash
./bin/down.sh
```