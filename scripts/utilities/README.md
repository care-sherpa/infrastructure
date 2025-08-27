# Utility Scripts

This folder contains operational utilities and tools for managing Care Sherpa infrastructure.

## Files

### Secret Management
- **`secret_manager_utility.sh`** - Interactive Google Secret Manager utility

## Secret Manager Utility

The `secret_manager_utility.sh` script provides a comprehensive interface for managing secrets across Care Sherpa projects.

### Features

- **Multi-project support**: Works with all Care Sherpa GCP projects
- **Interactive menus**: User-friendly selection interface
- **CRUD operations**: Create, read, update secrets
- **Security confirmations**: Prompts before displaying sensitive data
- **Auto-generation**: Can generate secure passwords automatically

### Usage

```bash
./secret_manager_utility.sh
```

#### Menu Options

1. **Project Selection**:
   - Option 1: Use default corp project (`halogen-honor-450420-q9`)
   - Option 2: List and select from all Care Sherpa projects

2. **Secret Operations**:
   - **Create**: New secret with auto-generated or manual password
   - **View**: Display existing secret (with confirmation)
   - **Update**: Add new version to existing secret

3. **Interactive Selection**:
   - Lists all secrets in selected project
   - Shows secret descriptions when available
   - Numbered selection interface

### Examples

#### Create New Secret
```bash
./secret_manager_utility.sh
# Select: 1 (default corp project)
# Select: 1 (create new secret)
# Enter name: analytics-user-password
# Select: 1 (generate automatically) or 2 (enter manually)
```

#### View Existing Secret
```bash
./secret_manager_utility.sh
# Select: 1 (default corp project)  
# Select: 2 (view existing secret)
# Select secret from numbered list
# Confirm: yes (to display secret value)
```

#### Update Secret
```bash
./secret_manager_utility.sh
# Select: 1 (default corp project)
# Select: 3 (update existing secret)  
# Select secret from numbered list
# Enter new value
# Confirm: yes
```

### Security Features

- **Confirmation prompts**: Requires explicit "yes" to view secrets
- **Hidden input**: Uses `read -s` for password entry
- **No temp files**: Secrets never touch filesystem
- **Access logging**: All operations logged by Google Cloud

### Default Project

The utility defaults to the **CareSherpaCorp** project (`halogen-honor-450420-q9`) which serves as the central secrets repository for all Care Sherpa infrastructure.

### Requirements

- Google Cloud SDK installed and authenticated
- Access to Care Sherpa GCP projects
- Secret Manager API enabled (already enabled in corp project)

### Shell Compatibility

The script works with:
- bash (Linux/macOS)
- zsh (macOS default)
- dash (Ubuntu sh)
- Other POSIX-compatible shells