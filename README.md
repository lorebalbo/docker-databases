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
MYSQL_ENABLED=false
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

Append any other docker compose arguments with `--`

```bash
./bin/up.sh -- -d --build
```

### Stop the services 🌊

To **stop** the services run:

```bash
./bin/down.sh
```

use the options:

- `-v` or `--volumes` to remove the volumes
- `-n` or `--networks` to remove the shared network
- `--rmi` to remove the images of the service

## Integrate in your Projects 💧

Set up your `.env` with the variables of the databases you need.

If you already have a `docker-compose.yml` **add the shared network** to it

```yml
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
./docker-databases/bin/up.sh -f your-project-compose.yml -e path/to/your/.env
```

## Available Services 🛢️

| Service | Default Port | Web Interface |
|---------|-------------|--------------|
| MySQL | 3306 | No |
| PostgreSQL | 5432 | No |
| MongoDB | 27017 | No |
| pgAdmin | 5050 | Yes - http://localhost:5050 |
| MongoDB Express | 8081 | Yes - http://localhost:8081 |
| MySQL Workbench | 3000 | Yes - http://localhost:3000 |