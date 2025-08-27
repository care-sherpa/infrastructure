#!/bin/bash

DBS=("analytics" "analytics-dev" "analytics-temp")
for db in "${DBS[@]}"; do
  echo "Applying grants to $db"
  PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d "$db" -f analytics_access.sql
done 