variable "project" {
  default = "caresherpaprod"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
}

variable "caresherpa_master_db_password" {
  sensitive = true
  type      = string
  description = "Database Password for caresherpa user"
}
