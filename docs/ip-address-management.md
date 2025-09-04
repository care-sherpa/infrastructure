# IP Address Management for Care Sherpa Infrastructure

## Overview

This document outlines the process for managing authorized network IP addresses in Care Sherpa's Google Cloud Platform infrastructure. IP addresses are now stored as Terraform variables instead of being hardcoded in configuration files, improving security and maintainability.

## Architecture

### Variable-Based Configuration

IP addresses are defined in environment-specific variable files:
- **Production**: `envs/prod/variables.tf`
- **Development**: `envs/dev/variables.tf`

### Network Types

#### Production Environment (`envs/prod/`)

1. **PostgreSQL Authorized Networks** (`var.postgres_authorized_networks`)
   - Controls access to the main PostgreSQL database
   - Default includes: Joseph Home, Keragon1-3, Ledom Home
   - Used by: Cloud SQL PostgreSQL instance

2. **MySQL Authorized Networks** (`var.mysql_authorized_networks`)
   - Controls access to the MySQL database
   - Default includes: Joseph Home, Ledom Home
   - Used by: Cloud SQL MySQL instance

3. **GKE Authorized Networks** (`var.gke_authorized_networks`)
   - Controls access to Kubernetes API server
   - Default includes: VPC subnet + 5 authorized external networks
   - Used by: GKE cluster master

#### Development Environment (`envs/dev/`)

1. **Database Authorized Networks** (`var.authorized_networks`)
   - Controls access to both PostgreSQL and MySQL databases
   - Default includes: Joseph Home, Ledom Home
   - Used by: Both database instances

2. **GKE Authorized Networks** (`var.gke_authorized_networks`)
   - Controls access to Kubernetes API server
   - Default includes: Dev VPC subnet, Joseph Home, Ledom Home
   - Used by: GKE cluster master

## Managing IP Addresses

### Adding a New IP Address

#### Production Environment

1. **For Database Access** (PostgreSQL/MySQL):
   ```bash
   cd envs/prod
   ```
   
   Edit `variables.tf` and add the new IP to the appropriate variable:
   ```hcl
   variable "postgres_authorized_networks" {
     default = [
       # existing entries...
       {
         name  = "New User Home"
         value = "1.2.3.4/32"
       }
     ]
   }
   ```

2. **For GKE Access**:
   ```hcl
   variable "gke_authorized_networks" {
     default = [
       # existing entries...
       {
         cidr_block   = "1.2.3.4/32"
         display_name = "New User Home"
       }
     ]
   }
   ```

3. **Apply Changes**:
   ```bash
   terraform plan -var-file=secrets.tfvars
   terraform apply -var-file=secrets.tfvars
   ```

#### Development Environment

1. **For Database Access**:
   ```bash
   cd envs/dev
   ```
   
   Edit `variables.tf`:
   ```hcl
   variable "authorized_networks" {
     default = [
       # existing entries...
       {
         name  = "New User Home"
         value = "1.2.3.4/32"
       }
     ]
   }
   ```

2. **For GKE Access**:
   ```hcl
   variable "gke_authorized_networks" {
     default = [
       # existing entries...
       {
         cidr_block   = "1.2.3.4/32"
         display_name = "New User Home"
       }
     ]
   }
   ```

3. **Apply Changes**:
   ```bash
   terraform plan
   terraform apply
   ```

### Removing an IP Address

1. Remove the IP address entry from the appropriate variable in `variables.tf`
2. Run `terraform plan` to verify the changes
3. Run `terraform apply` to implement the removal

### Updating an Existing IP Address

1. Locate the IP address in the appropriate variable
2. Update the `value` or `cidr_block` field
3. Update the `name` or `display_name` if needed
4. Apply the changes with Terraform

## Security Best Practices

### IP Address Format
- **Always use CIDR notation** (e.g., `192.168.1.1/32` for single IPs)
- **Use /32 subnet mask** for individual IP addresses
- **Validate IP addresses** before adding to avoid typos

### Network Naming
- **Use descriptive names** that identify the user or purpose
- **Follow consistent naming** (e.g., "FirstName Home", "Office Location")
- **Avoid exposing sensitive information** in display names

### Change Management
- **Test changes in development first** before applying to production
- **Document all changes** with appropriate commit messages
- **Review changes** with team members before applying
- **Monitor access logs** after making changes

### Regular Maintenance
- **Review IP addresses quarterly** to remove stale entries
- **Update IP addresses** when team members report connectivity issues
- **Audit authorized networks** as part of security reviews

## Validation and Testing

### Pre-Deployment Validation

1. **Syntax Check**:
   ```bash
   terraform validate
   ```

2. **Plan Review**:
   ```bash
   terraform plan -var-file=secrets.tfvars  # Production only
   terraform plan                           # Development
   ```

3. **IP Format Validation**:
   - Ensure all IPs use proper CIDR notation
   - Verify no duplicate entries exist
   - Check that IP addresses are valid

### Post-Deployment Testing

1. **Database Connectivity**:
   ```bash
   # Test PostgreSQL connection
   gcloud sql connect main-apps-db --user=caresherpa --database=analytics
   
   # Test MySQL connection
   gcloud sql connect prod-mysql-apps-db --user=root
   ```

2. **GKE Access**:
   ```bash
   # Get cluster credentials
   gcloud container clusters get-credentials cs-prod-apps-gke --zone=us-central1-a --project=caresherpaprod
   
   # Test API server access
   kubectl get nodes
   ```

3. **Connectivity from Authorized IPs**:
   - Test database access from each authorized IP
   - Verify kubectl commands work from authorized networks
   - Confirm unauthorized IPs are blocked

## Troubleshooting

### Common Issues

1. **Connection Timeout**:
   - Verify IP address is correctly formatted in variables
   - Check that Terraform changes were applied
   - Confirm the client IP matches the authorized network

2. **Authentication Errors**:
   - IP authorization is separate from user authentication
   - Ensure both IP is authorized AND user credentials are valid

3. **Terraform Apply Failures**:
   - Check for syntax errors in variable definitions
   - Verify all required variables are defined
   - Ensure proper CIDR notation is used

### Getting Current IP Address

```bash
# Get your current public IP
curl -s https://checkip.amazonaws.com/
curl -s https://ipinfo.io/ip
```

### Verifying Authorized Networks

```bash
# Check PostgreSQL authorized networks
gcloud sql instances describe main-apps-db --project=caresherpaprod --format="value(settings.ipConfiguration.authorizedNetworks[].value)"

# Check GKE authorized networks
gcloud container clusters describe cs-prod-apps-gke --zone=us-central1-a --project=caresherpaprod --format="value(masterAuthorizedNetworksConfig.cidrBlocks[].cidrBlock)"
```

## Integration with Existing Workflows

### Using with Deployment Scripts

The existing deployment scripts in `scripts/` will automatically use the new variable-based configuration:

```bash
# Production deployment
cd terraform-unified
./scripts/deploy-prod.sh plan
./scripts/deploy-prod.sh apply

# Development deployment
cd terraform-unified
./scripts/deploy-dev.sh plan
./scripts/deploy-dev.sh apply
```

### Overriding Variables at Runtime

For temporary access or testing, you can override variables:

```bash
# Override a single IP in production
terraform apply -var-file=secrets.tfvars -var='postgres_authorized_networks=[{name="Temp Access",value="1.2.3.4/32"}]'

# Use a custom variables file
terraform apply -var-file=secrets.tfvars -var-file=custom-ips.tfvars
```

## Monitoring and Alerts

### Recommended Monitoring

1. **Failed Connection Attempts**: Monitor for repeated failed connections from unauthorized IPs
2. **New IP Additions**: Track when authorized networks are modified
3. **Successful Connections**: Log successful database and API connections for audit purposes

### Google Cloud Monitoring

Set up alerts for:
- Unauthorized connection attempts to databases
- GKE API server access from new IPs
- Changes to authorized network configurations

## Compliance and Auditing

### Change Tracking
- All IP address changes are tracked in Git history
- Terraform state changes are logged
- Database connection logs provide audit trails

### Access Reviews
- Conduct quarterly reviews of all authorized IPs
- Remove IP addresses for departed team members
- Validate that all IPs are still required

### Documentation Requirements
- Document the business justification for each IP address
- Maintain contact information for IP address owners
- Record the services each IP address needs to access

---

## Quick Reference

### Current Authorized IPs (as of last update)

#### Production PostgreSQL
- Joseph Home: `68.89.9.20/32`
- Keragon3: `54.225.183.38`
- Keragon2: `34.197.3.75`
- Keragon1: `18.214.155.250`
- Ledom Home: `23.114.226.239/32`

#### Production MySQL
- Joseph Home: `68.89.9.20/32`
- Ledom Home: `23.114.226.239/32`

#### Production GKE
- VPC Subnet: `10.1.0.0/16`
- Authorized Network 1: `71.135.82.66/32`
- Authorized Network 2: `70.225.9.239/32`
- Authorized Network 3: `75.138.17.130/32`
- Authorized Network 4: `136.29.138.11/32`
- Authorized Network 5: `24.183.235.71/32`

#### Development
- Database access: Joseph Home (`68.89.9.20/32`), Ledom Home (`23.114.226.239/32`)
- GKE access: Dev VPC (`10.10.0.0/16`), Joseph Home (`68.89.9.20/32`), Ledom Home (`23.114.226.239/32`)