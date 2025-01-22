# init-db.sh

# Database name to create
DB_NAME="my_app"

# Create the database
/home/yugabyte/bin/ysqlsh --echo-queries --host "$(hostname)" -c "CREATE DATABASE $DB_NAME;"

if [ $? -eq 0 ]; then
  echo "Database '$DB_NAME' created successfully!"
else
  echo "Failed to create the database '$DB_NAME'."
fi
