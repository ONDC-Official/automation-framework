#!/bin/bash

# Container name of YugabyteDB
CONTAINER_NAME="yugabyte"

# Database name to create
DB_NAME="my_app"

# Execute the command inside the Yugabyte container
docker exec -it $CONTAINER_NAME bash -c "/home/yugabyte/bin/ysqlsh --echo-queries --host \$(hostname) -c 'CREATE DATABASE $DB_NAME;'"

# docker exec -it $CONTAINER_NAME ysqlsh -c "CREATE DATABASE $DB_NAME;"
if [ $? -eq 0 ]; then
  echo "Database '$DB_NAME' created successfully!"
else
  echo "Failed to create the database '$DB_NAME'."
fi

