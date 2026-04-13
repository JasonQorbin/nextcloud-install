#!/bin/bash

# Check if required variables are set
if [ -z "$DB_LOCATION" ]; then
    echo "Error: DB_LOCATION is not set."
    exit 1
fi

if [ -z "$DB_ROOT_PASSWORD" ]; then
    echo "Error: DB_ROOT_PASSWORD is not set."
    exit 1
fi

if [ -z "$NC_DB_USER_NAME" ]; then
    echo "Error: NC_DB_USER_NAME is not set."
    exit 1
fi

if [ -z "$NC_DB_PASSWORD" ]; then
    echo "Error: NC_DB_PASSWORD is not set."
    exit 1
fi

# Check if a database name was provided
if [ -z "$NC_DB_NAME" ]; then
    echo "Using '${NC_DB_NAME}' as the database name."
else
    export NC_DB_NAME='nextcloud'
    echo "Using the default database name: '${NC_DB_NAME}'"
fi

# Run the init script in the mariadb container, by passing the sript to the mysql command and a parameter and running as root.

docker exec -i mariadb mysql -u root -p ${DB_ROOT_PASSWORD} < ./init_db.sql


