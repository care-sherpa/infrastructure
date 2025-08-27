#!/bin/bash

echo "Setting up Joseph Levy's access to suitecrm-dev database..."

# Execute the MySQL script to create user and grant permissions
mysql -h 34.133.76.154 -u "$CRM_DB_USER" -p"$CRM_DB_PASS" < suitecrm_access.sql

echo "Access setup complete!"
echo ""
echo "Joseph can now connect to the suitecrm-dev database using:"
echo "Host: 34.133.76.154"
echo "Database: suitecrm-dev"
echo "Username: joseph.levy"
echo "Password: Care\$herpa2025!"
echo ""
echo "Connection string example:"
echo "mysql -h 34.133.76.154 -u joseph.levy -p suitecrm-dev" 