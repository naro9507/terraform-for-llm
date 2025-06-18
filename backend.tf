terraform {
  backend "gcs" {
    bucket = "terraform-states-bucket"
    prefix = "terraform/state"
  }
}
