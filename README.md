# Care Sherpa Infrastructure

This repository contains Google Cloud Platform infrastructure definitions, Kubernetes configurations, and operational scripts for the Care Sherpa platform.

## Repository Structure

```
├── terraform/
│   ├── prod/          # Production infrastructure
│   └── dev/           # Development infrastructure  
├── k8s/               # Kubernetes configurations
│   ├── emissary/      # Emissary ingress controller
│   └── ingress/       # Load balancer and SSL certificates
├── scripts/
│   ├── database/      # Database setup and access scripts
│   └── utilities/     # Operational utilities
└── README.md
```

## Available Resources

### Infrastructure (Terraform)
- **Production Environment** (`terraform/prod/`): Complete GKE cluster, databases, networking
- **Development Environment** (`terraform/dev/`): Cloud Workstations and development resources

### Scripts & Utilities
- **Database Scripts** (`scripts/database/`): User management, permissions, access setup
- **Utilities** (`scripts/utilities/`): Secret management, operational tools

### Kubernetes Configurations
- **Emissary Ingress**: API gateway and load balancing
- **SSL Certificates**: Managed certificates for custom domains
- **Load Balancer**: Google Cloud Load Balancer integration

## Quick Start

### Prerequisites
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated
- [Terraform](https://terraform.io) installed
- Access to Care Sherpa GCP projects

### Setup
1. **Authentication**: 
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

2. **Secret Management**: Use the interactive utility for managing secrets
   ```bash
   ./scripts/utilities/secret_manager_utility.sh
   ```

3. **Database Setup**: See `scripts/database/README.md` for database configuration


Order of Operations:
1. Run a terraform init/plan/apply from the _prod_ folder to get the following resources created in GCP:
    1. VPC Network - private-network-caresherpa
    2. Compute Subnet - subnet:
    3. Secondary IP Range - caresherpa-gke-cluster-ip-range; 10.2.0.0/20
    4. Secondary IP Range - caresherpa-gke-service-ip-range; 192.168.0.0/24
    5. Private IP Address - private-ip-postgres
    6. Private VPC Connection - private-ip-postgres to private-network-caresherpa
    7. Compute Firewall - allow-iap-to-vm
    8. Cloud Router - cloud-router
    9. Cloud Nat - cloud-nat
    10. Reserved Global IP Address - lb-svc-address
    11. Postgres Instance - main-apps-db
    12. 3 SQL Databases:
        1. careproject
        2. careanalytics
        3. caremap
    13. Cloud SQL User
    14. GKE Cluster - cs-prod-apps-gke
    15. GKE Node Pool - apps-1-node-pool
    16. Artifact Repository - cs-docker
    17. Artifact Repository IAM Member Mapping - member-tf-sa
2. Install Emissary Ingress using Helm: https://www.getambassador.io/docs/emissary/latest/topics/install/helm/
3. Apply YAML in yaml/ingress - this will create two GCP load balancers
4. Apply YAML in yaml/emissary - this updates the emissary resources to work behind the load balancers
5. Apply YAML in yaml/analytics, yaml/expedition, yaml/map


