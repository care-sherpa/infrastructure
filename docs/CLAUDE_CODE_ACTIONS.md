# Claude Code Actions Instructions

## Overview
This document provides instructions for a Claude Code Actions agent working in a cloud environment with **terraform plan-only** access. The agent will help build and validate modular Terraform configurations based on exported GCP infrastructure.

## Available Files

### Infrastructure Export Data
- `temp-gcp-export/networks.json` - VPC networks and routing
- `temp-gcp-export/subnets.json` - Subnet configurations and IP ranges  
- `temp-gcp-export/firewall.json` - Firewall rules and security policies
- `temp-gcp-export/routers.json` - Cloud routers and NAT configurations
- `temp-gcp-export/sql-instances.json` - Cloud SQL instance configurations
- `temp-gcp-export/sql-databases.json` - Database schemas and settings
- `temp-gcp-export/sql-users.json` - Database users and permissions
- `temp-gcp-export/gke-clusters.json` - GKE cluster configurations
- `temp-gcp-export/gke-node-pools.json` - Node pool settings and scaling
- `temp-gcp-export/iam-policy.json` - Project IAM policies and bindings
- `temp-gcp-export/artifact-repositories.json` - Artifact Registry repositories
- `temp-gcp-export/current-terraform-state.json` - Current Terraform state snapshot

## Agent Capabilities
- **Read files** to understand existing infrastructure
- **Create/edit Terraform files** for modular architecture
- **Run `terraform plan` only** - NO apply operations
- **Validate configurations** against existing infrastructure
- **Document findings** and recommended changes

## Task: Create Modular Terraform Architecture

### Target Structure
```
modules/
├── networking/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── databases/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── kubernetes/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── security/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── README.md

envs/
├── prod/
│   ├── main.tf
│   ├── variables.tf
│   ├── backend.tf
│   └── terraform.tfvars
└── dev/
    ├── main.tf
    ├── variables.tf
    ├── backend.tf
    └── terraform.tfvars
```

## Implementation Steps

### Phase 1: Analysis
1. **Read exported JSON files** to understand current infrastructure
2. **Analyze current-terraform-state.json** to identify all resources
3. **Document resource relationships** and dependencies
4. **Plan module boundaries** based on resource groupings

### Phase 2: Create Networking Module
5. **Create `modules/networking/`** directory and files
6. **Extract networking resources** from current state:
   - `google_compute_network.private_network`
   - `google_compute_subnetwork.subnet`
   - `google_compute_router.cloud_router`
   - `google_compute_router_nat.cloud_nat`
   - `google_compute_firewall.allow-iap-to-vm`

7. **Create module variables** for environment-specific configuration
8. **Create module outputs** for other modules to reference
9. **Create prod environment** composition calling networking module
10. **Run terraform plan** to validate configuration

### Phase 3: Validate Zero Changes
11. **Initialize prod environment** with separate state backend
12. **Import networking resources** using terraform import commands:
```bash
terraform import module.networking.google_compute_network.private_network projects/caresherpaprod/global/networks/private-network-caresherpa
terraform import module.networking.google_compute_subnetwork.subnet projects/caresherpaprod/regions/us-central1/subnetworks/private-network-caresherpa-subnet
terraform import module.networking.google_compute_router.cloud_router projects/caresherpaprod/regions/us-central1/routers/cloud-router
terraform import module.networking.google_compute_router_nat.cloud_nat projects/caresherpaprod/regions/us-central1/routers/cloud-router/cloud-nat
terraform import module.networking.google_compute_firewall.allow-iap-to-vm projects/caresherpaprod/global/firewalls/allow-iap-to-vm
```

13. **Run terraform plan** and validate ZERO changes for production
14. **Document any configuration drift** and required fixes

### Phase 4: Progressive Module Creation
15. **Repeat process for databases module** (Cloud SQL resources)
16. **Create kubernetes module** (GKE cluster and node pools)  
17. **Create security module** (IAM, Artifact Registry)
18. **Validate each module** shows zero changes individually

## Expected Production Resources

### Networking Module Resources
- Network: `private-network-caresherpa`
- Subnet: `private-network-caresherpa-subnet` (10.1.0.0/16)
- Secondary ranges for GKE pods/services
- Cloud Router: `cloud-router`
- Cloud NAT: `cloud-nat`
- Firewall rule: `allow-iap-to-vm`

### Databases Module Resources
- PostgreSQL instance: `main-apps-db`
- MySQL instance: `prod-mysql-apps-db` 
- Databases: `openempi`, `analytics`, `map`
- Database users and permissions

### Kubernetes Module Resources
- GKE cluster: `cs-prod-apps-gke`
- Node pool: `apps-1-node-pool` (4-8 nodes)
- Node pool: `data-1-node-pool` (3-6 nodes)
- Cluster networking integration

### Security Module Resources
- Artifact Registry: `cs-docker`
- IAM service accounts and bindings
- Security policies

## Validation Criteria
- [ ] Each module runs `terraform plan` with zero changes
- [ ] Module outputs provide necessary references for other modules
- [ ] Environment compositions use modules correctly
- [ ] Resource names match existing production exactly
- [ ] All current functionality is preserved

## Environment Configuration Patterns

### Production Environment
```hcl
# envs/prod/terraform.tfvars
environment = "prod"
project_id = "caresherpaprod"
region = "us-central1"
zone = "us-central1-a"

# No name prefix for production (keep existing names)
name_prefix = ""

# Production-sized resources
node_pool_config = {
  apps_min_nodes = 4
  apps_max_nodes = 8
  data_min_nodes = 3
  data_max_nodes = 6
}
```

### Development Environment  
```hcl
# envs/dev/terraform.tfvars
environment = "dev"
project_id = "caresherpadev-448722"
region = "us-central1"
zone = "us-central1-a"

# Dev prefix for new resources
name_prefix = "dev-"

# Smaller dev resources
node_pool_config = {
  apps_min_nodes = 1
  apps_max_nodes = 3
  data_min_nodes = 1
  data_max_nodes = 2
}
```

## Backend Configuration

### Production Backend
```hcl
# envs/prod/backend.tf
terraform {
  backend "gcs" {
    bucket = "cs_prodtfstate"
    prefix = "environments/prod-modular"
  }
}
```

### Development Backend
```hcl
# envs/dev/backend.tf  
terraform {
  backend "gcs" {
    bucket = "cs_prodtfstate"
    prefix = "environments/dev-modular"
  }
}
```

## Troubleshooting Common Issues

### Configuration Drift
- Compare exported JSON with Terraform configuration
- Update configuration to match existing resource attributes
- Document any intentional changes for future reference

### Import Failures
- Verify resource exists using exported JSON data
- Check resource naming and project configuration
- Validate provider configuration matches existing setup

### Plan Shows Changes
- Review resource attributes in exported data
- Update Terraform configuration to match exactly
- Consider if changes are acceptable for migration

## Success Metrics
1. **Zero Changes**: Production plan shows no changes
2. **Module Isolation**: Each module can be planned independently  
3. **Environment Separation**: Dev environment deploys successfully
4. **Resource Preservation**: All existing functionality maintained
5. **Documentation**: Clear README files for each module

## Next Steps After Validation
Once all modules show zero changes:
1. Test development environment deployment
2. Create CI/CD integration for automated validation
3. Document migration from legacy terraform-unified structure
4. Plan sunset of old unified configuration