#!/bin/bash

set -e

#
 # Create the database if it does not exist
#
if [ -n "$POSTGRES_DB" ]; then
  psql --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    SELECT 'CREATE DATABASE "$POSTGRES_DB"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$POSTGRES_DB')\gexec
EOSQL
fi