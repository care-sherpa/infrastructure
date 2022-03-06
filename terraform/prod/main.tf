data "google_client_config" "default" {}

terraform {
  required_version = ">= 0.15.5"

  required_providers {
    google = {
      source = "hashicorp/google"
    }

    google-beta = {
     source = "hashicorp/google-beta"
    }
  }

  backend "gcs" {
    bucket = "cs_prodtfstate"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  cs_projects = toset(["openempi", "analytics", "map"])
}

#
# Net
#
resource "google_compute_network" "private_network" {
  name     = "private-network-caresherpa"
}

resource "google_compute_subnetwork" "subnet" {
  depends_on    = [google_compute_network.private_network]
  name          = "private-network-caresherpa-subnet"
  ip_cidr_range = "10.1.0.0/16"
  region        = "${var.region}"
  network       = "${google_compute_network.private_network.name}"

  secondary_ip_range {
    range_name    = "caresherpa-gke-cluster-ip-range"
    ip_cidr_range = "10.2.0.0/20"
  }

  secondary_ip_range {
    range_name    = "caresherpa-gke-service-ip-range"
    ip_cidr_range = "192.168.0.0/24"
  }
}

resource "google_compute_global_address" "private_ip" {
  depends_on    = [google_compute_network.private_network]
  name          = "private-ip-postgres"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  depends_on              = [google_compute_network.private_network]
  network                 = google_compute_network.private_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

resource "google_compute_firewall" "allow-iap-to-vm" {
  depends_on  = [google_compute_network.private_network]
  name        = "allow-iap-to-vm"
  network     = google_compute_network.private_network.self_link
  description = "Allow IAP to VMs"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_router" "cloud_router" {
  depends_on = [google_compute_network.private_network]
  name       = "cloud-router"
  network    = google_compute_network.private_network.self_link
  region     = "${var.region}"
}

resource "google_compute_router_nat" "cloud_nat" {
  depends_on                         = [google_compute_router.cloud_router]
  name                               = "cloud-nat"
  router                             = google_compute_router.cloud_router.name
  region                             = "${var.region}"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "lb-address" {
  name          = "lb-svc-address"
  address_type  = "EXTERNAL"
  project       = "${var.project}"
}

#
# PostgreSQL
#
resource "google_sql_database_instance" "main-apps-db" {
  depends_on          = [google_compute_network.private_network]
  name                = "main-apps-db"
  database_version    = "POSTGRES_13"
  region              = "${var.region}"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
    availability_type = "REGIONAL"

    ip_configuration {
      private_network = google_compute_network.private_network.self_link

      ipv4_enabled = true
      authorized_networks {
        name = "Brett home"
        value = "75.138.17.130"
      }
      authorized_networks {
        name = "McCraw home"
        value = "24.183.235.71/32"
      }
    }

    location_preference {
      zone = var.zone
    }

    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "database" {
  for_each = local.cs_projects

  name      = each.key
  instance  = "${google_sql_database_instance.main-apps-db.name}"
}

resource "google_sql_user" "user" {
  name     = "caresherpa"
  instance = "${google_sql_database_instance.main-apps-db.name}"
  password = "${var.caresherpa_master_db_password}"
}

#
# K8s
#
module "gke" {
  depends_on                      = [google_compute_subnetwork.subnet]

  source                          = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                      = "${var.project}"
  name                            = "cs-prod-apps-gke"
  regional                        = false
  region                          = "${var.region}"
  zones                           = ["${var.zone}"]
  kubernetes_version              = "1.21.6-gke.1500"
  network                         = "private-network-caresherpa"
  subnetwork                      = "private-network-caresherpa-subnet"
  ip_range_pods                   = "caresherpa-gke-cluster-ip-range"
  ip_range_services               = "caresherpa-gke-service-ip-range"
  create_service_account          = true
  http_load_balancing             = true
  horizontal_pod_autoscaling      = true
  network_policy                  = false
  remove_default_node_pool        = true
  initial_node_count              = 1
  enable_private_nodes            = true
  enable_vertical_pod_autoscaling = false

  node_pools = [
    {
      name                      = "apps-1-node-pool"
      machine_type              = "e2-medium"
      min_count                 = 1
      max_count                 = 3
      local_ssd_count           = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      auto_repair               = true
      auto_upgrade              = true
      initial_node_count        = 2
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = "${google_compute_subnetwork.subnet.ip_cidr_range}"
      display_name = "csvpc"
    },
    {
      cidr_block   = "71.135.82.66/32"
      display_name = "Hen Home"
    },
    {
      cidr_block   = "24.183.235.71/32"
      display_name = "McCraw Home" 
    }
  ]  
}

#
# Artifact Repository
#
resource "google_artifact_registry_repository" "cs-docker" {
  provider = google-beta

  location      = "${var.region}"
  repository_id = "cs-docker"
  description   = "docker image repository"
  format        = "DOCKER"
  project       = "${var.project}"
}

resource "google_artifact_registry_repository_iam_member" "member-tf-sa" {
  depends_on = [google_artifact_registry_repository.cs-docker]
  provider   = google-beta
  project    = "${var.project}"
  location   = "${var.region}"
  repository = "${google_artifact_registry_repository.cs-docker.repository_id}"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke.service_account}"
}