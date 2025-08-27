# Database Scripts

This folder contains SQL scripts and utilities for managing database users, permissions, and access.

## Files

### SQL Scripts
- **`analytics_access.sql`** - Creates analytics database user with read/write permissions
- **`suitecrm_access.sql`** - Manages SuiteCRM database access and permissions

### Utilities
- **`create_readonly_user.sh`** - Creates read-only database users

## Usage

### Analytics Access Setup

The analytics access script creates a user for database access with secure password management:

1. **Create the secret** (store password in Google Secret Manager):
   ```bash
   ../../scripts/utilities/secret_manager_utility.sh
   ```
   - Create secret named: `analytics-user-password`
   - Use corp project: `halogen-honor-450420-q9`

2. **Connect to database** and run the script:
   ```bash
   # Get the password from Secret Manager
   ANALYTICS_PASSWORD=$(gcloud secrets versions access latest --secret=analytics-user-password --project=halogen-honor-450420-q9)
   
   # Connect to PostgreSQL and set variable
   psql -h [HOST] -d analytics -U caresherpa
   \set analytics_password 'YOUR_PASSWORD_HERE'
   \i analytics_access.sql
   ```

3. **User created**: `joseph.levy` with analytics_readwrite permissions

### Security Notes

- **No hardcoded passwords**: All passwords are managed via Google Secret Manager
- **Least privilege**: Users are granted minimal required permissions
- **Audit trail**: All database changes are logged

### Database Connection Info

After running the scripts, users can connect with:
- **Host**: Get from `gcloud sql instances describe main-apps-db --format='value(connectionName)'`
- **Database**: `analytics` 
- **Username**: `joseph.levy`
- **Password**: Retrieved from Google Secret Manager

## Requirements

- Google Cloud SDK installed and authenticated
- Access to Care Sherpa GCP projects
- PostgreSQL client tools
- Appropriate database permissions