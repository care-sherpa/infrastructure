terraform {
  required_version = ">= 0.15.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 7.0"
    }
  }

  backend "gcs" {
    bucket = "caresherpa-terraform-state-v2"
    prefix = "environments/dev-v2"
  }
}