terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "cs_prodtfstate"
    prefix = "environments/dev"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC for dev workspace
resource "google_compute_network" "dev_vpc" {
  name                    = "dev-workspace-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dev_subnet" {
  name          = "dev-workspace-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.dev_vpc.id
  region        = var.region
}

# Cloud Workstations configuration
resource "google_workstations_workstation_cluster" "dev_cluster" {
  name               = "dev-workspace-cluster"
  network            = google_compute_network.dev_vpc.id
  subnetwork         = google_compute_subnetwork.dev_subnet.id
  location           = var.region
  display_name       = "Development Workspace Cluster"
}

resource "google_workstations_workstation_config" "dev_config" {
  name               = "dev-workspace-config"
  workstation_cluster_id = google_workstations_workstation_cluster.dev_cluster.id
  location           = var.region
  
  host {
    gce_instance {
      machine_type                = "e2-standard-4"
      boot_disk_size_gb           = 50
      disable_public_ip_addresses = true
      tags                        = ["dev-workspace"]
    }
  }

  container {
    image = "us-docker.pkg.dev/cloud-workstations-images/predefined/code-oss:latest"
  }
}

# Secure storage for PII data
resource "google_storage_bucket" "pii_data" {
  name          = "${var.project_id}-pii-data"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
  encryption {
    default_kms_key_name = google_kms_crypto_key.pii_key.id
  }
}

# KMS key for PII data encryption
resource "google_kms_key_ring" "pii_keyring" {
  name     = "pii-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "pii_key" {
  name     = "pii-key"
  key_ring = google_kms_key_ring.pii_keyring.id
  
  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# IAM roles and permissions
resource "google_service_account" "dev_workspace_sa" {
  account_id   = "dev-workspace-sa"
  display_name = "Development Workspace Service Account"
}

resource "google_project_iam_member" "dev_workspace_sa_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.dev_workspace_sa.email}"
}

resource "google_project_iam_member" "dev_workspace_sa_kms" {
  project = var.project_id
  role    = "roles/cloudkms.cryptoKeyDecrypter"
  member  = "serviceAccount:${google_service_account.dev_workspace_sa.email}"
}

# Grant OS Login external user update permission to bwiggins@trycatchdev.com
resource "google_project_iam_member" "bwiggins_oslogin_update" {
  project = var.project_id
  role    = "roles/compute.oslogin.updateExternalUser"
  member  = "user:bwiggins@trycatchdev.com"
}

# Network security
resource "google_compute_firewall" "dev_workspace" {
  name    = "dev-workspace-firewall"
  network = google_compute_network.dev_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dev-workspace"]
} 