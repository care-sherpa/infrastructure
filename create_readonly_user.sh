# For analytics
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics -c "GRANT USAGE ON SCHEMA public TO analytics_readonly;"
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;"
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analytics_readonly;"

# For analytics-dev
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics-dev -c "GRANT USAGE ON SCHEMA public TO analytics_readonly;"
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics-dev -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_readonly;"
PGPASSWORD="$CRM_DB_PASS" psql -h 35.223.169.97 -p 5432 -U "$CRM_DB_USER" -d analytics-dev -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO analytics_readonly;"