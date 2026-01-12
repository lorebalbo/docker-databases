#!/bin/bash

set -e

# ------------------------------------------------------------------------------
# Variables

source .env

# ------------------------------------------------------------------------------

clean_pg_database() {
    local container_name=$1
    local username=$2
    local database=$3

    if docker exec -it $container_name bash -c "psql -U $username -lqt | cut -d \| -f 1 | grep -qw $database" > /dev/null; then
        # Ask for user confirmation
        read -p "Are you sure you want to clean the database '$database'? This action cannot be undone. (y/n): " confirm
    else
        confirm="y"
    fi

    if [[ $confirm == [yY] ]]; then
        # Drop the existing database if it exists
        docker exec -it $container_name bash -c "
            psql -U $username -d postgres -t -c \"SELECT 1 FROM pg_database WHERE datname = '$database'\" | grep -q 1 &&
            dropdb -U $username -f \"$database\";

            # Create the new database with proper quoting
            psql -U $username -d postgres -c \"CREATE DATABASE \\\"$database\\\"\"
        " > /dev/null

        echo
        echo "Database '$database' deleted and recreated successfully."
    else
        echo "Database deletion aborted."
    fi
}

clean_mysql_database() {
    local container_name=$1
    local database=$2
    local username=$3
    local password=$4

    local mysql_command="mysql -u${username} -e"

    if docker exec -i -e MYSQL_PWD="${password}" "${container_name}" ${mysql_command} "SHOW DATABASES LIKE '${database}';" | grep -q "${database}"; then
        read -p "Sei sicuro di voler pulire e ricreare il database '$database'? L'azione è irreversibile. (y/n): " confirm
    else
        echo "Il database '$database' non esiste, verrà creato."
        confirm="y"
    fi

    if [[ $confirm =~ ^[yY]([eE][sS])?$ ]]; then
        local sql_query="DROP DATABASE IF EXISTS \`${database}\`; CREATE DATABASE \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

        # Eseguiamo la query SQL.
        docker exec -i -e MYSQL_PWD="${password}" "${container_name}" ${mysql_command} "${sql_query}" > /dev/null

        echo
        echo "Database '$database' pulito e ricreato con successo."
    else
        echo "Operazione annullata."
    fi
}

clean_mongo_database() {
    local container_name=$1
    local database=$2
    local username=$3
    local password=$4

    # Build the connection string (URI).
    # `authSource=admin` is often required because user credentials
    # are typically stored in the 'admin' database.
    local mongo_uri="mongodb://${username}:${password}@localhost:27017/${database}?authSource=admin"

    # To list all databases, it is better to connect to the 'admin' database.
    local admin_uri="mongodb://${username}:${password}@localhost:27017/admin?authSource=admin"

    # Check if database exists
    if docker exec -i "$container_name" mongosh --quiet "${admin_uri}" --eval "db.getMongo().getDBNames().join('\n')" | grep -qwx "$database"; then
        # Ask for user confirmation
        read -p "Are you sure you want to clean the database '$database'? This action cannot be undone. (y/n): " confirm
    else
        echo "No database found to clean."
    fi

    if [[ $confirm =~ ^[yY]([eE][sS])?$ ]]; then
        docker exec -i "$container_name" mongosh --quiet "${mongo_uri}" --eval "db.dropDatabase()" > /dev/null

        echo
        echo "Database '$database' cleaned successfully."
        else
        echo "Database deletion aborted."
    fi
}

clean_databases() {
    # Accetta come argomenti:
    # - la lista di nomi di databases da eliminare
    # - la lista di dbms a cui appartengono i databases

    # Esempi:
    # databases=("db1" "db2")
    # dbms=("postgres" "mysql")

    # databases=("db1" "db2")
    # Se dbms non viene passato, si eliminano quei database da tutti i dbms

    local databases=()
    local dbms=()

    while [[ $# -gt 0 && $1 != --* ]]; do
        databases+=("$1")
        shift
    done

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dbms)
                shift
                while [[ $# -gt 0 && $1 != --* ]]; do
                    dbms+=("$1")
                    shift
                done
                ;;
            *)
                echo "Unknown parameter: $1"
                echo "Usage: clean_databases db1 db2 [--dbms postgres mysql]"
                return 1
                ;;
        esac
    done

    # If no DBMS is specified, use all the available ones
    if [[ ${#dbms[@]} -eq 0 ]]; then
        if $POSTGRES_ENABLED; then
            dbms+=("postgres")
        fi
        if $MONGO_ENABLED; then
            dbms+=("mongodb")
        fi
        if $MYSQL_ENABLED; then
            dbms+=("mysql")
        fi
    else
        # filter out dbms not enabled
        for i in "${!dbms[@]}"; do
            if [[ ! ${dbms[i]}_ENABLED ]]; then
                unset 'dbms[i]'
            fi
        done
    fi

    # If databases are not specified, show error
    if [[ ${#databases[@]} -eq 0 ]]; then
        echo "Error: No databases specified"
        echo "Usage: clean_databases db1 db2 [--dbms postgres mysql]"
        return 1
    fi

    # Per ogni DBMS specificato
    for current_dbms in "${dbms[@]}"; do
        case $current_dbms in
            postgres)
                local container_name="${DOCKER_POSTGRES_CONTAINER_NAME}"
                local username="${POSTGRES_USERNAME}"
                local password="${POSTGRES_PASSWORD}"

                if [[ -z "$username" || -z "$password" ]]; then
                    echo "Warning: Missing PostgreSQL environment variables (POSTGRES_USERNAME, POSTGRES_PASSWORD)"
                    continue
                fi

                echo "Cleaning PostgreSQL databases..."
                for db in "${databases[@]}"; do
                    echo "Processing database: $db in PostgreSQL container: $container_name"
                    _clean_database "$container_name" "$username" "$db"
                done
                ;;
            mongo)
                local container_name="${DOCKER_MONGO_CONTAINER_NAME}"
                local username="${MONGO_USERNAME}"
                local password="${MONGO_PASSWORD}"

                echo "Cleaning MongoDB databases..."
                for db in "${databases[@]}"; do
                    echo "Processing database: $db in MongoDB container: $container_name"
                    clean_mongo_database "$container_name" "$db" "$username" "$password"
                done
                ;;
            mysql)
                local container_name="${DOCKER_MYSQL_CONTAINER_NAME}"
                local username="${root}"
                local password="${MYSQL_ROOT_PASSWORD}"

                if [[ -z "$password" ]]; then
                    echo "Warning: Missing MySQL environment variables (MYSQL_PASSWORD or MYSQL_ROOT_PASSWORD)"
                    continue
                fi

                echo "Cleaning MySQL databases..."
                for db in "${databases[@]}"; do
                    echo "Processing database: $db in MySQL container: $container_name"
                    clean_mysql_database "$container_name" "$db" "$username" "$password"
                    echo "MySQL cleanup not implemented yet for database: $db"
                done
                ;;
            *)
                echo "Warning: Unsupported DBMS: $current_dbms"
                ;;
        esac
    done
}

for arg in "$@"
do
    case $arg in
        --help|-h)
            echo "Usage: $0 db1 db2 [--dbms postgres mysql mongodb]"
            echo ""
            echo "Arguments:"
            echo "  db1 db2 ...    Database names to clean"
            echo "  --dbms         Specify which DBMS to use (optional)"
            echo ""
            echo "Examples:"
            echo "  $0 mydb"
            echo "  $0 db1 db2 --dbms postgres"
            echo "  $0 testdb --dbms postgres mysql"
            exit 0
            ;;
    esac
done

# Call the clean_databases function with all arguments
clean_databases "$@"
