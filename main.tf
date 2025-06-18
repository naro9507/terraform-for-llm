terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_storage_bucket" "terraform_state_bucket" {
  name                        = "${var.project}-tfstate"
  location                    = "asia-northeast1"
  uniform_bucket_level_access = true
  project                     = var.project
}
