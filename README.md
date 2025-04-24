# Docker Compose Databases 🐳

Set up **MySQL**, **MongoDB**, **PostgreSQL**, **pgAdmin**, **MongoDB Express** and **MySQL Workbench** using Docker.

## Usage 🐋

Set up the **environment variables**:

```bash
cp .env.example .env
```

**Choose the databases** you want to use by setting the corresponding environment variable to `true`:

```bash
POSTGRES_ENABLED=true
PGADMIN_ENABLED=true
MONGO_ENABLED=false
MONGOEXPRS_ENABLED=false
...
```

### Start the services 🐳

To **start** the services, run:

```bash
./bin/up.sh
```

use the options:
- `-f` to add a custom docker-compose.yml
- `-e` to use your own .env file
- `--dry-run` to show the command that would be run without executing it

Append any **other compose arguments** with `--`

```bash
./bin/up.sh -e .env.test -- -d --build
```

### Stop the services 🌊

To **stop** the services run:

```bash
./bin/down.sh
```

use the options:

- `-n` or `--networks` to remove the shared network
- `--dry-run` to show the command that would be run without executing it

Append any **other compose arguments** with `--`

```bash
./bin/up.sh -n -- -d --volumes
```

## Integrate in your Projects 💧

Set up your `.env` with the variables of the databases you need.

If you already have a `docker-compose.yml` **add the shared network** to it

```yml
# ./your-project-compose.yml

services:
    backend:
        ...
        networks:
            - shared

networks:
    shared:
        name: ${DOCKER_NETWORK_NAME:-devnet}
        external: true
```

To **start** the services, run:

```bash
./docker-databases/bin/up.sh -f your-project-compose.yml -e path/to/your/.env -- -d
```

Use the `DOCKER_PROJECT_NAME` to perform action on the compose's active services

```bash
docker compose -p DOCKER_PROJECT_NAME ps
```

If `DOCKER_PROJECT_NAME` is not set in your `.env` the project name is the root directory.