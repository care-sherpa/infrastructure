# IP Address Management Process

## Overview

This document outlines the process for managing authorized network IP addresses in the Care Sherpa infrastructure. IP addresses are now managed through Terraform variables instead of being hardcoded in configuration files.

## Security Improvements

Previously, IP addresses were hardcoded directly in `envs/prod/main.tf` and `envs/dev/main.tf` files. This created several security and maintenance issues:

- **Version control exposure**: Personal IP addresses were committed to version control
- **Maintenance burden**: Changes required code modifications and redeployment
- **Stale access rules**: No process for regular review and cleanup

## Current Architecture

IP addresses are now managed through Terraform variables defined in:

- `envs/prod/variables.tf` - Production environment authorized networks
- `envs/dev/variables.tf` - Development environment authorized networks

### Variable Structure

#### Production Environment

- `postgres_authorized_networks` - PostgreSQL database access (5 networks)
- `mysql_authorized_networks` - MySQL database access (2 networks)  
- `gke_authorized_networks` - GKE master API access (6 networks)

#### Development Environment

- `authorized_networks` - Database access for both PostgreSQL and MySQL (2 networks)
- `gke_authorized_networks` - GKE master API access (3 networks)

## Managing IP Address Changes

### Adding a New IP Address

1. **Determine the environment and service type** (prod/dev, database/GKE)

2. **Update the appropriate variable** in `envs/{env}/variables.tf`:
   ```hcl
   default = [
     # existing entries...
     {
       name  = "Descriptive Name"
       value = "192.168.1.100/32"  # Use /32 for single IPs
     }
   ]
   ```

3. **Plan and apply changes**:
   ```bash
   cd envs/{env}
   terraform plan
   terraform apply
   ```

### Removing an IP Address

1. **Remove the entry** from the appropriate variable in `envs/{env}/variables.tf`

2. **Plan and apply changes**:
   ```bash
   cd envs/{env}
   terraform plan
   terraform apply
   ```

### Updating an Existing IP Address

1. **Modify the value** in the appropriate variable in `envs/{env}/variables.tf`

2. **Plan and apply changes**:
   ```bash
   cd envs/{env}
   terraform plan
   terraform apply
   ```

## Security Best Practices

1. **Use descriptive names**: Always provide clear, descriptive names for each authorized network entry

2. **Use proper CIDR notation**: Single IP addresses should use `/32` suffix

3. **Regular reviews**: Conduct quarterly reviews to validate all authorized networks are still required

4. **Principle of least privilege**: Only add networks that require direct access to the services

5. **Test in development first**: Always test IP address changes in the dev environment before applying to production

## Validation Process

Before applying changes:

1. **Validate syntax**:
   ```bash
   terraform validate
   ```

2. **Review the plan**:
   ```bash
   terraform plan
   ```

3. **Test connectivity** after applying changes to ensure authorized networks can still access the services

## Emergency Access

If immediate access is required and Terraform deployment is not possible:

1. **Use Google Cloud Console** to temporarily add the IP address directly
2. **Document the emergency change** and create a ticket for proper Terraform integration
3. **Update the Terraform variables** and apply to maintain consistency

## Monitoring and Auditing

- Monitor Google Cloud Audit Logs for unauthorized network access attempts
- Review authorized networks quarterly and remove any that are no longer needed
- Keep documentation updated when team members join or leave

## Related Files

- `envs/prod/variables.tf` - Production authorized networks
- `envs/dev/variables.tf` - Development authorized networks
- `envs/prod/main.tf` - Production infrastructure configuration
- `envs/dev/main.tf` - Development infrastructure configuration