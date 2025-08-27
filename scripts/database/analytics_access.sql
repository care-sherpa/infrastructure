-- Check if role exists, create if not
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analytics_readwrite') THEN
        CREATE ROLE analytics_readwrite
        WITH
            LOGIN
            NOINHERIT
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOREPLICATION;
    END IF;
END
$$;

-- Grant CONNECT on analytics DB
GRANT CONNECT ON DATABASE analytics TO analytics_readwrite;

-- Grant USAGE on schemas
GRANT USAGE ON SCHEMA public TO analytics_readwrite;
GRANT USAGE ON SCHEMA inbound TO analytics_readwrite;

-- Grant schema modification permissions (for adding columns, etc.)
GRANT CREATE ON SCHEMA public TO analytics_readwrite;
GRANT CREATE ON SCHEMA inbound TO analytics_readwrite;

-- Grant access to specific tables
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "analytics-dev" TO analytics_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "analytics-temp" TO analytics_readwrite;

-- Grant table-level privileges (only on tables owned by current user)
DO $$
DECLARE
    r record;
BEGIN
    FOR r IN (SELECT schemaname, tablename FROM pg_tables WHERE schemaname IN ('public', 'inbound') AND tableowner = current_user)
    LOOP
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE %I.%I TO analytics_readwrite', 
                      r.schemaname, r.tablename);
    END LOOP;
END
$$;

-- Set default privileges for future tables (use CURRENT_USER)
DO $$
BEGIN
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analytics_readwrite',
      SESSION_USER
    );
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA inbound GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO analytics_readwrite',
      SESSION_USER
    );
END
$$;

-- Create joseph.levy as a regular Postgres user (if not exists) with a password from Google Secret Manager
-- 
-- SETUP REQUIRED:
-- 1. Run: ../../scripts/utilities/secret_manager_utility.sh (interactive utility, defaults to corp project)
-- 2. Create or view secret: analytics-user-password  
-- 3. Connect to DB and set variable: \set analytics_password 'YOUR_PASSWORD_HERE'
-- 4. Run this script: \i analytics_access.sql
--
-- Or use command line: 
-- ANALYTICS_PASSWORD=$(gcloud secrets versions access latest --secret=analytics-user-password --project=halogen-honor-450420-q9)

DO $$
BEGIN
 IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'joseph.levy') THEN
  CREATE USER "joseph.levy" WITH PASSWORD :'analytics_password';
 ELSE
  -- Uncomment below to reset password if needed:
  -- ALTER USER "joseph.levy" WITH PASSWORD :'analytics_password';
 END IF;
END
$$;

-- (Grant analytics_readwrite to joseph.levy (regular user) (and remove GRANT for matt.ledomcare-sherpa.com (which does not exist) and the commented IAM GRANT for joseph.levy@care-sherpa.com) (Remaining verification queries remain unchanged.)

GRANT analytics_readwrite TO "joseph.levy";


-- Grant analytics_readwrite role to evaluation_app user
GRANT analytics_readwrite TO evaluation_app;


-- (Removed or commented out the IAM GRANT for joseph.levy@care-sherpa.com (and removed GRANT for matt.ledomcare-sherpa.com (which does not exist)) (Remaining verification queries remain unchanged.)

-- (Remaining verification queries remain unchanged.)
\echo '\nVerifying role setup:'
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolreplication FROM pg_roles WHERE rolname = 'analytics_readwrite';

\echo '\nVerifying schema privileges:'
SELECT grantee, table_schema, privilege_type FROM information_schema.role_table_grants WHERE grantee = 'analytics_readwrite' AND table_schema IN ('public', 'inbound') ORDER BY table_schema, privilege_type;
