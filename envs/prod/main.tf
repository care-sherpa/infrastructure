provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  # No prefix for production (keep existing names)
  name_prefix = ""
  
  network_config = {
    network_name        = "private-network-caresherpa"
    subnet_name         = "private-network-caresherpa-subnet"
    subnet_cidr         = "10.1.0.0/16"
    pods_cidr          = "10.2.0.0/20"
    services_cidr      = "192.168.0.0/24"
    pods_range_name    = "caresherpa-gke-cluster-ip-range"
    services_range_name = "caresherpa-gke-service-ip-range"
  }
  
  # Authorized networks for MySQL (only 2 networks)
  mysql_authorized_networks = [
    {
      name  = "Joseph Home"
      value = "68.89.9.20/32"
    },
    {
      name  = "Ledom Home" 
      value = "23.114.226.239/32"
    }
  ]
  
  # Authorized networks for PostgreSQL (5 networks)
  postgres_authorized_networks = [
    {
      name  = "Joseph Home"
      value = "68.89.9.20/32"
    },
    {
      name  = "Keragon3"
      value = "54.225.183.38"
    },
    {
      name  = "Keragon2"
      value = "34.197.3.75"
    },
    {
      name  = "Keragon1"
      value = "18.214.155.250"
    },
    {
      name  = "Ledom Home" 
      value = "23.114.226.239/32"
    }
  ]
  
  # PostgreSQL configuration
  postgres_config = {
    instance_name         = "main-apps-db"
    database_version     = "POSTGRES_13"
    tier                 = "db-g1-small"
    disk_size           = 10
    disk_type           = "PD_SSD"
    availability_type   = "REGIONAL"
    backup_enabled      = true
    backup_start_time   = "03:00"
    deletion_protection = true
    maintenance_day     = 1
    maintenance_hour    = 0
    secondary_zone      = "us-central1-f"
    database_flags = [
      {
        name  = "cloudsql.iam_authentication"
        value = "on"
      }
    ]
  }
  
  # MySQL configuration
  mysql_config = {
    instance_name         = "prod-mysql-apps-db"
    database_version     = "MYSQL_8_0"
    tier                 = "db-custom-2-7680"
    disk_size           = 157
    disk_type           = "PD_SSD"
    availability_type   = "REGIONAL"
    backup_enabled      = true
    backup_start_time   = "00:00"
    deletion_protection = true
    maintenance_day     = 7
    maintenance_hour    = 8
    secondary_zone      = "us-central1-c"
    database_flags = [
      {
        name  = "log_bin_trust_function_creators"
        value = "on"
      }
    ]
  }
  
  # PostgreSQL databases to create
  postgres_databases = [
    "airbyte",
    "postgres", 
    "map",
    "openempi",
    "temporal",
    "analytics",
    "metabase",
    "temporal_visibility",
    "airflow",
    "airflow-alt",
    "keycloak",
    "analytics-temp",
    "analytics-dev"
  ]

  # GKE cluster configuration
  cluster_config = {
    cluster_name                               = "cs-prod-apps-gke"
    pods_range_name                           = "caresherpa-gke-cluster-ip-range"
    services_range_name                       = "caresherpa-gke-service-ip-range"
    enable_private_nodes                      = true
    enable_private_endpoint                   = false
    master_ipv4_cidr_block                   = "172.16.0.0/28"
    disable_horizontal_pod_autoscaling       = false
    disable_http_load_balancing              = false
    disable_network_policy                   = true
    enable_gce_persistent_disk_csi_driver    = true
    enable_gke_backup_agent                  = true
    autoscaling_profile                      = "BALANCED"
  }

  # GKE node pools configuration
  node_pools = {
    apps = {
      name              = "apps-1-node-pool"
      min_node_count    = 1
      max_node_count    = 8
      preemptible       = false
      machine_type      = "e2-medium"
      disk_size_gb      = 100
      disk_type         = "pd-standard"
      service_account   = "tf-gke-cs-prod-apps-gk-yuxk@caresherpaprod.iam.gserviceaccount.com"
      oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
      auto_repair       = true
      auto_upgrade      = true
    }
    data = {
      name              = "data-1-node-pool"
      min_node_count    = 3
      max_node_count    = 6
      preemptible       = false
      machine_type      = "e2-medium"
      disk_size_gb      = 100
      disk_type         = "pd-standard"
      service_account   = "tf-gke-cs-prod-apps-gk-yuxk@caresherpaprod.iam.gserviceaccount.com"
      oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
      auto_repair       = true
      auto_upgrade      = true
      taints = []
    }
  }

  # GKE authorized networks for master access
  gke_authorized_networks = [
    {
      cidr_block   = "10.1.0.0/16"
      display_name = "VPC Subnet"
    },
    {
      cidr_block   = "71.135.82.66/32"
      display_name = "Authorized Network 1"
    },
    {
      cidr_block   = "70.225.9.239/32"
      display_name = "Authorized Network 2"
    },
    {
      cidr_block   = "75.138.17.130/32"
      display_name = "Authorized Network 3"
    },
    {
      cidr_block   = "136.29.138.11/32"
      display_name = "Authorized Network 4"
    },
    {
      cidr_block   = "24.183.235.71/32"
      display_name = "Authorized Network 5"
    }
  ]

  # Artifact Registry configuration
  registry_config = {
    repository_id           = "cs-docker"
    description            = "docker image repository"
    cleanup_policy_dry_run = true
    cleanup_policies       = []
  }

  # Static IP configuration
  static_ip_config = {
    name        = "lb-svc-address"
    description = "Static IP for load balancer service"
  }

  # Service accounts configuration
  service_accounts = {
    gke_node = {
      account_id   = "tf-gke-cs-prod-apps-gk-yuxk"
      display_name = "GKE Node Service Account"
      description  = "Service account for GKE nodes"
      roles = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/monitoring.viewer"
      ]
    }
  }
}

module "networking" {
  source = "../../modules/networking"
  
  environment    = var.environment
  project_id     = var.project_id
  region         = var.region
  name_prefix    = local.name_prefix
  network_config = local.network_config
  enable_gke     = true
}

module "databases" {
  source = "../../modules/databases"
  
  environment                   = var.environment
  project_id                   = var.project_id
  region                       = var.region
  zone                         = var.zone
  name_prefix                  = local.name_prefix
  network_self_link            = module.networking.network_self_link
  postgres_authorized_networks = local.postgres_authorized_networks
  mysql_authorized_networks    = local.mysql_authorized_networks
  postgres_config              = local.postgres_config
  mysql_config                 = local.mysql_config
  postgres_databases           = local.postgres_databases
}

module "kubernetes" {
  source = "../../modules/kubernetes"
  
  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  name_prefix          = local.name_prefix
  network_name         = module.networking.network_name
  subnet_name          = module.networking.subnet_name
  cluster_config       = local.cluster_config
  authorized_networks  = local.gke_authorized_networks
  node_pools           = local.node_pools
}

module "security" {
  source = "../../modules/security"
  
  project_id        = var.project_id
  region            = var.region
  name_prefix       = local.name_prefix
  registry_config   = local.registry_config
  static_ip_config  = local.static_ip_config
  service_accounts  = local.service_accounts
}