# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This repository manages Care Sherpa's Google Cloud Platform infrastructure using a multi-environment approach:

- **Production Environment** (`caresherpaprod`): Complete GKE cluster with PostgreSQL/MySQL databases, private networking, and Emissary ingress
- **Development Environment** (`caresherpadev-448722`): Currently Cloud Workstations setup, intended to mirror production with smaller resources  
- **Corporate Project** (`halogen-honor-450420-q9`): Centralized secrets management and Terraform state storage

### Key Infrastructure Components

**Production Architecture** (`terraform/prod/`):
- Private GKE cluster (`cs-prod-apps-gke`) with 2 node pools (apps: 4-8 nodes, data: 3-6 nodes)
- PostgreSQL 13 instance (`main-apps-db`) with databases: `openempi`, `analytics`, `map`  
- MySQL 8.0 instance (`prod-mysql-apps-db`)
- Private VPC (`private-network-caresherpa`) with secondary IP ranges for K8s pods/services
- Google Artifact Registry (`cs-docker`) for container images
- Static load balancer IP (`lb-svc-address`: `34.149.148.14`)

**Kubernetes Setup**:
- Uses Emissary ingress controller for API gateway functionality
- SSL certificates managed via GKE Managed Certificates for `caresherpa.us` domains
- Cloud Armor security policies for access control

## Common Commands

### Unified Terraform Operations (Recommended)
```bash
# Production infrastructure
cd terraform-unified
./scripts/deploy-prod.sh init
./scripts/deploy-prod.sh plan    # Requires secrets.tfvars for database password
./scripts/deploy-prod.sh apply

# Development infrastructure  
cd terraform-unified
./scripts/deploy-dev.sh init
./scripts/deploy-dev.sh plan
./scripts/deploy-dev.sh apply
```

### Legacy Terraform Operations  
```bash
# Production infrastructure (legacy)
cd terraform/prod
terraform init -backend-config="prefix=environments/prod"
terraform plan -var-file=secrets.tfvars
terraform apply -var-file=secrets.tfvars

# Development infrastructure (legacy)
cd terraform/dev  
terraform init -backend-config="prefix=environments/dev"
terraform plan
terraform apply
```

### Secret Management
```bash
# Interactive secret management (defaults to corp project halogen-honor-450420-q9)
./scripts/utilities/secret_manager_utility.sh

# Command line secret retrieval
gcloud secrets versions access latest --secret=analytics-user-password --project=halogen-honor-450420-q9
```

### Database Setup
```bash
# Connect to production database
gcloud sql connect main-apps-db --user=caresherpa --database=analytics

# Run analytics access script (requires password from Secret Manager)
\set analytics_password 'PASSWORD_FROM_SECRET_MANAGER'
\i scripts/database/analytics_access.sql
```

### Kubernetes Operations
```bash
# Get cluster credentials
gcloud container clusters get-credentials cs-prod-apps-gke --zone=us-central1-a --project=caresherpaprod

# Apply ingress configurations
kubectl apply -f k8s/ingress/
kubectl apply -f k8s/emissary/
```

## Project Structure and Conventions

### Repository Structure
```
├── terraform-unified/     # Unified Terraform configuration (RECOMMENDED)
│   ├── main.tf           # Environment-aware infrastructure
│   ├── variables.tf      # Variable definitions
│   ├── environments/     # Environment-specific variables
│   │   ├── prod.tfvars   # Production settings
│   │   └── dev.tfvars    # Development settings  
│   └── scripts/          # Deployment automation
│       ├── deploy-prod.sh
│       └── deploy-dev.sh
├── terraform/            # Legacy separate configurations
│   ├── prod/             # Production-specific (legacy)
│   └── dev/              # Development-specific (legacy)
└── scripts/              # Operational scripts
    ├── database/         # Database management
    └── utilities/        # Secret management, etc.
```

### Multi-Project Setup
- **Production**: `caresherpaprod` - All production infrastructure and workloads
- **Development**: `caresherpadev-448722` - Development workloads
- **Corporate**: `halogen-honor-450420-q9` - Centralized secrets and Terraform state storage

### Terraform State Management
**Centralized State Bucket**: `gs://caresherpa-terraform-state-v2` (Corporate Project)
- **Location**: `us-central1` region in `halogen-honor-450420-q9` project
- **Versioning**: Enabled with lifecycle management
  - Keeps 5 versions of each state file
  - Guarantees minimum 2 versions always retained
  - Auto-deletes versions older than 90 days (beyond minimum)
- **Access**: Least privilege permissions
  - Production SA: `261612620243-compute@developer.gserviceaccount.com`
  - Development SA: `236981169202-compute@developer.gserviceaccount.com`
  - Roles: `storage.objectAdmin` + `storage.legacyBucketReader`

### Modular Infrastructure Architecture
The repository uses a modular approach with environment-specific compositions:
```
├── modules/              # Reusable infrastructure components
│   ├── networking/       # VPC, subnets, NAT, firewall
│   ├── databases/        # Cloud SQL instances and configuration
│   ├── kubernetes/       # GKE cluster and node pools
│   └── security/         # IAM, artifact registry, policies
└── envs/                 # Environment compositions
    ├── prod/             # Production environment (caresherpaprod)
    │   ├── backend.tf    # State: prefix=environments/prod-v2
    │   └── main.tf       # Calls modules with prod parameters
    └── dev/              # Development environment (caresherpadev-448722)
        ├── backend.tf    # State: prefix=environments/dev-v2
        └── main.tf       # Calls modules with dev parameters
```

**Environment Differences**:
- **Resource sizing**: Production uses larger instances, dev uses minimal resources
- **Naming**: Production uses existing names, dev uses `dev-` prefixes
- **State isolation**: Separate prefixes in shared state bucket

### Secret Management Pattern
All passwords and sensitive data are stored in Google Secret Manager in the corporate project. Database scripts use psql variables (`:variable_name`) and require manual password input from Secret Manager to avoid hardcoded credentials.

### Infrastructure Deployment Order
1. Terraform infrastructure (VPC, databases, GKE cluster)
2. Emissary Ingress Helm installation
3. Kubernetes ingress configurations (creates GCP load balancers)  
4. Emissary configuration updates
5. Application deployments

### DNS and SSL Management
- Production uses managed certificates for `*.caresherpa.us` domains
- Development will use `*.dev.caresherpa.com` (planned)
- Static IP reservations are managed in Terraform for consistent load balancer addressing

## Important Context

- The `terraform/dev/terraform.tfvars` specifies `care-sherpa-dev` but the actual GCP project ID is `caresherpadev-448722`
- Database user `joseph.levy` is created via `analytics_access.sql` with password stored in Secret Manager as `analytics-user-password`
- All networking uses private IP ranges with Cloud NAT for outbound connectivity
- Authorized networks for database and K8s access include team member home IPs
- Kubernetes uses Workload Identity for secure pod-to-GCP service authentication