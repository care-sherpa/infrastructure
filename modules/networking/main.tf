#
# Network Infrastructure Module
#

# VPC Network
resource "google_compute_network" "private_network" {
  name                    = "${var.name_prefix}${var.network_config.network_name}"
  auto_create_subnetworks = true
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  depends_on    = [google_compute_network.private_network]
  name          = "${var.name_prefix}${var.network_config.subnet_name}"
  ip_cidr_range = var.network_config.subnet_cidr
  region        = var.region
  network       = google_compute_network.private_network.name
  project       = var.project_id

  # Only add secondary ranges for GKE environments
  dynamic "secondary_ip_range" {
    for_each = var.enable_gke ? [1] : []
    content {
      range_name    = var.network_config.pods_range_name
      ip_cidr_range = var.network_config.pods_cidr
    }
  }

  dynamic "secondary_ip_range" {
    for_each = var.enable_gke ? [1] : []
    content {
      range_name    = var.network_config.services_range_name
      ip_cidr_range = var.network_config.services_cidr
    }
  }
}

# Firewall rules
resource "google_compute_firewall" "allow-iap-to-vm" {
  depends_on  = [google_compute_network.private_network]
  name        = "${var.name_prefix}allow-iap-to-vm"
  network     = google_compute_network.private_network.self_link
  description = "Allow IAP to VMs"
  direction   = "INGRESS"
  project     = var.project_id

  allow {
    protocol = "tcp"
  }

  source_ranges = ["35.235.240.0/20"]
}

# NAT for outbound connectivity
resource "google_compute_router" "cloud_router" {
  depends_on = [google_compute_network.private_network]
  name       = "${var.name_prefix}cloud-router"
  network    = google_compute_network.private_network.self_link
  region     = var.region
  project    = var.project_id
}

resource "google_compute_router_nat" "cloud_nat" {
  depends_on                         = [google_compute_router.cloud_router]
  name                               = "${var.name_prefix}cloud-nat"
  router                             = google_compute_router.cloud_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private services connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.name_prefix}private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.private_network.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}