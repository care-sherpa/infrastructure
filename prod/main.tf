data "google_client_config" "default" {}

terraform {
  required_version = ">= 0.15.5"

  required_providers {
    google = {
      source = "hashicorp/google"
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

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  cs_projects = toset(["careproject", "careanalytics", "caremap"])
}

#
# Compute
#
resource "google_compute_network" "private_network" {
  name     = "private-network-caresherpa"
}

resource "google_compute_subnetwork" "subnet" {
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
  name          = "private-ip-postgres"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

#
# PostgreSQL
#
resource "google_sql_database_instance" "main-db" {
  depends_on          = [google_compute_network.private_network]
  name                = "main-db"
  database_version    = "POSTGRES_13"
  region              = "${var.region}"
  deletion_protection = false

  settings {
    tier = "db-g1-small"
    availability_type = "REGIONAL"

    ip_configuration {
      private_network = google_compute_network.private_network.self_link

      ipv4_enabled = false
    }

    location_preference {
      zone = var.zone
    }
  }
}

resource "google_sql_database" "database" {
  for_each = local.cs_projects

  name      = each.key
  instance  = "${google_sql_database_instance.main-db.name}"
}

resource "google_sql_user" "user" {
  name     = "caresherpa"
  instance = "${google_sql_database_instance.main-db.name}"
  password = "${var.caresherpa_master_db_password}"
}

#
# K8s
#
module "gke" {
  depends_on                 = [google_compute_subnetwork.subnet]

  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = "${var.project}"
  name                       = "cs-prod-apps-gke"  
  regional                   = false
  region                     = "${var.region}"
  zones                      = ["${var.zone}"]
  network                    = "private-network-caresherpa"
  subnetwork                 = "private-network-caresherpa-subnet"
  ip_range_pods              = "caresherpa-gke-cluster-ip-range"
  ip_range_services          = "caresherpa-gke-service-ip-range"
  create_service_account     = true
  http_load_balancing        = false
  horizontal_pod_autoscaling = false
  network_policy             = true
  remove_default_node_pool   = true
  initial_node_count         = 1
  enable_private_nodes       = true

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-medium"
      min_count                 = 1
      max_count                 = 2
      local_ssd_count           = 0
      disk_size_gb              = 10
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
  ]  
}