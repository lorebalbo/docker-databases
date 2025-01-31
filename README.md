# Docker Compose Databases

Set up **MySQL**, **MongoDB**, **PostgreSQL** and **pgAdmin** using Docker.

## Usage

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

To **start** the services, run:

```bash
./bin/up.sh
```

To start the services with a specific **environment file**, run:

```bash
./bin/up.sh -e path/to/your/.env
```

### Stop the services

To **stop** the services run:

```bash
./bin/down.sh
```

to **remove** also the **volumes**, run:

```bash
./bin/down.sh -v
```
