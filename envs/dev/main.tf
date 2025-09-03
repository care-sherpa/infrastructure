provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  # Dev prefix to distinguish from production
  name_prefix = "dev-"
  
  network_config = {
    network_name        = "private-network-caresherpa"
    subnet_name         = "private-network-caresherpa-subnet"
    subnet_cidr         = "10.10.0.0/16"
    pods_cidr          = "10.11.0.0/20"
    services_cidr      = "192.168.1.0/24"
    pods_range_name    = "caresherpa-gke-cluster-ip-range"
    services_range_name = "caresherpa-gke-service-ip-range"
  }
  
  # Authorized networks for databases - now using variables
  authorized_networks = var.authorized_networks
  
  # PostgreSQL configuration (smaller instance for dev)
  postgres_config = {
    instance_name         = "main-apps-db"
    database_version     = "POSTGRES_13"
    tier                 = "db-f1-micro"
    disk_size           = 10
    disk_type           = "PD_SSD"
    availability_type   = "ZONAL"
    backup_enabled      = true
    backup_start_time   = "03:00"
    deletion_protection = false
    maintenance_day     = 7
    maintenance_hour    = 0
    secondary_zone      = null
    database_flags = []
  }
  
  # MySQL configuration (smaller instance for dev)
  mysql_config = {
    instance_name         = "mysql-apps-db"
    database_version     = "MYSQL_8_0"
    tier                 = "db-f1-micro"
    disk_size           = 10
    disk_type           = "PD_SSD"
    availability_type   = "ZONAL"
    backup_enabled      = true
    backup_start_time   = "00:00"
    deletion_protection = false
    maintenance_day     = 7
    maintenance_hour    = 8
    secondary_zone      = null
    database_flags = []
  }
  
  # PostgreSQL databases to create (subset for dev)
  postgres_databases = [
    "postgres", 
    "analytics",
    "temporal",
    "temporal_visibility",
    "airflow"
  ]

  # GKE cluster configuration (smaller for dev)
  cluster_config = {
    cluster_name                               = "cs-apps-gke"
    pods_range_name                           = "caresherpa-gke-cluster-ip-range"
    services_range_name                       = "caresherpa-gke-service-ip-range"
    enable_private_nodes                      = true
    enable_private_endpoint                   = false
    master_ipv4_cidr_block                   = "172.17.0.0/28"
    disable_horizontal_pod_autoscaling       = false
    disable_http_load_balancing              = false
    disable_network_policy                   = true
    enable_gce_persistent_disk_csi_driver    = true
    enable_gke_backup_agent                  = true
    autoscaling_profile                      = "BALANCED"
  }

  # GKE node pools configuration (sized for dev workloads)
  node_pools = {
    apps = {
      name              = "apps-node-pool"
      min_node_count    = 1
      max_node_count    = 4
      preemptible       = true
      machine_type      = "e2-standard-2"  # 2 vCPUs, 8GB RAM
      disk_size_gb      = 50
      disk_type         = "pd-standard"
      service_account   = "default"
      oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
      auto_repair       = true
      auto_upgrade      = true
    }
    data = {
      name              = "data-node-pool"
      min_node_count    = 1
      max_node_count    = 2
      preemptible       = true
      machine_type      = "e2-standard-2"  # 2 vCPUs, 8GB RAM
      disk_size_gb      = 50
      disk_type         = "pd-standard"
      service_account   = "default"
      oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
      auto_repair       = true
      auto_upgrade      = true
      taints = []
    }
  }

  # GKE authorized networks for master access - now using variables  
  gke_authorized_networks = var.gke_authorized_networks

  # Artifact Registry configuration
  registry_config = {
    repository_id           = "cs-docker"
    description            = "Development docker image repository"
    cleanup_policy_dry_run = true
    cleanup_policies       = []
  }

  # Static IP configuration
  static_ip_config = {
    name        = "lb-svc-address"
    description = "Dev static IP for load balancer service"
  }

  # Service accounts configuration
  service_accounts = {
    gke_node = {
      account_id   = "gke-node-sa"
      display_name = "Dev GKE Node Service Account"
      description  = "Service account for dev GKE nodes"
      roles = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/monitoring.viewer"
      ]
    }
  }

  # Database users configuration
  db_users = {}
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
  private_vpc_connection       = module.networking.private_vpc_connection
  postgres_authorized_networks = local.authorized_networks
  mysql_authorized_networks    = local.authorized_networks
  postgres_config              = local.postgres_config
  mysql_config                 = local.mysql_config
  postgres_databases           = local.postgres_databases
  db_users                     = local.db_users
  db_user_passwords            = module.security.db_user_passwords
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
  db_users          = local.db_users
}