-- Create joseph.levy user if not exists
CREATE USER IF NOT EXISTS 'joseph.levy'@'%' IDENTIFIED BY 'Care$herpa2025!';

-- Grant access to suitecrm-dev database
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `suitecrm-dev`.* TO 'joseph.levy'@'%';

-- Grant access to suitecrm database (in case he needs access to production too)
-- GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `suitecrm`.* TO 'joseph.levy'@'%';

-- Grant access to inbound database (for data integration)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON `inbound`.* TO 'joseph.levy'@'%';

-- Flush privileges to apply changes
FLUSH PRIVILEGES;

-- Show the created user and their privileges
SELECT User, Host FROM mysql.user WHERE User = 'joseph.levy';
SHOW GRANTS FOR 'joseph.levy'@'%'; 