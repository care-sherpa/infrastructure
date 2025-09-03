#
# Kubernetes Infrastructure Module
#

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.name_prefix}${var.cluster_config.cluster_name}"
  location = var.zone
  project  = var.project_id

  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = "projects/${var.project_id}/global/networks/${var.network_name}"
  subnetwork = "projects/${var.project_id}/regions/${var.region}/subnetworks/${var.subnet_name}"

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_config.pods_range_name
    services_secondary_range_name = var.cluster_config.services_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.cluster_config.enable_private_nodes
    enable_private_endpoint = var.cluster_config.enable_private_endpoint
    master_ipv4_cidr_block  = var.cluster_config.master_ipv4_cidr_block
  }

  # Master authorized networks
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Add-ons configuration
  addons_config {
    horizontal_pod_autoscaling {
      disabled = var.cluster_config.disable_horizontal_pod_autoscaling
    }
    
    http_load_balancing {
      disabled = var.cluster_config.disable_http_load_balancing
    }

    network_policy_config {
      disabled = var.cluster_config.disable_network_policy
    }

    gce_persistent_disk_csi_driver_config {
      enabled = var.cluster_config.enable_gce_persistent_disk_csi_driver
    }

    gke_backup_agent_config {
      enabled = var.cluster_config.enable_gke_backup_agent
    }
  }

  # Autoscaling profile
  cluster_autoscaling {
    autoscaling_profile = var.cluster_config.autoscaling_profile
  }
}

# Node pools
resource "google_container_node_pool" "apps" {
  name       = "${var.name_prefix}${var.node_pools.apps.name}"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.project_id

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.node_pools.apps.min_node_count
    max_node_count = var.node_pools.apps.max_node_count
  }

  # Node configuration
  node_config {
    preemptible  = var.node_pools.apps.preemptible
    machine_type = var.node_pools.apps.machine_type
    disk_size_gb = var.node_pools.apps.disk_size_gb
    disk_type    = var.node_pools.apps.disk_type

    service_account = var.node_pools.apps.service_account
    oauth_scopes    = var.node_pools.apps.oauth_scopes

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = var.node_pools.apps.auto_repair
    auto_upgrade = var.node_pools.apps.auto_upgrade
  }
}

resource "google_container_node_pool" "data" {
  name       = "${var.name_prefix}${var.node_pools.data.name}"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  project    = var.project_id

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.node_pools.data.min_node_count
    max_node_count = var.node_pools.data.max_node_count
  }

  # Node configuration
  node_config {
    preemptible  = var.node_pools.data.preemptible
    machine_type = var.node_pools.data.machine_type
    disk_size_gb = var.node_pools.data.disk_size_gb
    disk_type    = var.node_pools.data.disk_type

    service_account = var.node_pools.data.service_account
    oauth_scopes    = var.node_pools.data.oauth_scopes

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Data node pool specific taints
    dynamic "taint" {
      for_each = var.node_pools.data.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = var.node_pools.data.auto_repair
    auto_upgrade = var.node_pools.data.auto_upgrade
  }
}