terraform {
  backend "gcs" {
    bucket = "cs_prodtfstate"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_sql_database_instance" "pg-main" {
  name = "pg-main"
  database_version = "POSTGRES_13"
  region       = "${var.region}"

  settings {
    tier = "db-g1-small"
  }
}