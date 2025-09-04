# IP Address Management Guide

This document outlines the process for managing authorized network IP addresses for Care Sherpa's infrastructure components.

## Overview

Authorized networks control access to sensitive infrastructure components:
- **PostgreSQL databases**: Production (5 networks) and Development (2 networks)
- **MySQL databases**: Production (2 networks) and Development (2 networks) 
- **GKE clusters**: Production (6 networks) and Development (3 networks)

All IP addresses are now managed through Terraform variables instead of hardcoded values for improved security and maintainability.

## Configuration Structure

### Production Environment (`envs/prod/`)
Variables defined in `variables.tf`:
- `postgres_authorized_networks`: List of authorized networks for PostgreSQL
- `mysql_authorized_networks`: List of authorized networks for MySQL  
- `gke_authorized_networks`: List of authorized networks for GKE cluster

### Development Environment (`envs/dev/`)
Variables defined in `variables.tf`:
- `authorized_networks`: Shared list for both database types
- `gke_authorized_networks`: List of authorized networks for GKE cluster

## Adding or Removing IP Addresses

### Method 1: Update Variable Defaults (Recommended)
1. Edit the appropriate `variables.tf` file
2. Update the `default` value for the relevant variable
3. Test in development environment first
4. Apply changes using deployment scripts

**Example - Adding a new IP to production PostgreSQL:**
```hcl
variable "postgres_authorized_networks" {
  description = "List of authorized networks for PostgreSQL database"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    # ... existing entries ...
    {
      name  = "New Office Location"
      value = "203.0.113.100/32"
    }
  ]
}
```

### Method 2: Override with tfvars (Advanced)
1. Create or edit `terraform.tfvars` in the environment directory
2. Override the variable values
3. Pass the tfvars file during deployment

**Example - tfvars override:**
```hcl
postgres_authorized_networks = [
  {
    name  = "Joseph Home"
    value = "68.89.9.20/32"
  },
  {
    name  = "New Team Member"
    value = "198.51.100.10/32"
  }
]
```

## Deployment Process

### Development Environment Testing
```bash
cd terraform-unified
./scripts/deploy-dev.sh plan
./scripts/deploy-dev.sh apply
```

### Production Environment Deployment
```bash
cd terraform-unified
./scripts/deploy-prod.sh plan    # Review changes carefully
./scripts/deploy-prod.sh apply
```

## Security Best Practices

1. **Least Privilege**: Only add IP addresses that require access
2. **CIDR Notation**: Always use /32 for single IP addresses
3. **Descriptive Names**: Use clear, identifiable names for networks
4. **Regular Auditing**: Review authorized networks quarterly
5. **Testing First**: Always test changes in development environment
6. **Documentation**: Update this guide when adding new procedures

## Validation Steps

After making IP changes:

1. **Terraform Validation**:
   ```bash
   terraform validate
   terraform plan
   ```

2. **Database Connectivity Test**:
   ```bash
   # Test PostgreSQL connection
   gcloud sql connect main-apps-db --user=caresherpa --database=analytics

   # Test MySQL connection  
   gcloud sql connect prod-mysql-apps-db --user=root
   ```

3. **GKE Cluster Access Test**:
   ```bash
   gcloud container clusters get-credentials cs-prod-apps-gke \
     --zone=us-central1-a --project=caresherpaprod
   kubectl get nodes
   ```

## Common IP Address Ranges

Current authorized networks (as of implementation):

### Production Database Networks
- `68.89.9.20/32`: Joseph Home
- `54.225.183.38`: Keragon3 (EC2)
- `34.197.3.75`: Keragon2 (EC2)  
- `18.214.155.250`: Keragon1 (EC2)
- `23.114.226.239/32`: Ledom Home

### Production GKE Networks
- `10.1.0.0/16`: VPC Subnet
- `71.135.82.66/32`: Authorized Network 1
- `70.225.9.239/32`: Authorized Network 2
- `75.138.17.130/32`: Authorized Network 3
- `136.29.138.11/32`: Authorized Network 4
- `24.183.235.71/32`: Authorized Network 5

### Development Networks
- `68.89.9.20/32`: Joseph Home
- `23.114.226.239/32`: Ledom Home
- `10.10.0.0/16`: Dev VPC Subnet

## Emergency Access

If immediate access is required:
1. Use Google Cloud Console to temporarily add IP
2. Document the change immediately
3. Update Terraform variables within 24 hours
4. Apply Terraform to make change permanent

## Troubleshooting

**Connection Denied**:
1. Verify IP address is correctly added to authorized networks
2. Check if IP uses correct CIDR notation (/32 for single IPs)
3. Confirm Terraform changes have been applied
4. Allow 5-10 minutes for changes to propagate

**Terraform Plan Shows Unexpected Changes**:
1. Ensure all team members are using same variable values
2. Check for manual changes made via Google Cloud Console
3. Import any manually created resources into Terraform state

## Security Incidents

If unauthorized access is suspected:
1. Immediately review all authorized networks
2. Remove any unrecognized IP addresses
3. Apply Terraform changes immediately
4. Review access logs in Google Cloud Console
5. Document incident and remediation steps