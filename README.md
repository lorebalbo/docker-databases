# Docker Compose Databases

This project sets up PostgreSQL, MongoDB, MySQL and pgAdmin using Docker Compose.

## Usage

Set up the environment variables:

```bash
cp .env.example .env
```

Choose the database you want to use by setting the corresponding environment variable to `true`:

```bash
POSTGRES_ENABLED=true
MYSQL_ENABLED=false
...
```

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