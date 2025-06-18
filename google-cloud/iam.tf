# For Terraform
resource "google_service_account" "terraform_runner_service_account" {
  account_id   = "terraform-runner"
  display_name = "Terraform実行のためのService Account"
  project      = var.project
}

resource "google_storage_bucket_iam_member" "terraform_state_bucket_iam" {
  bucket = google_storage_bucket.terraform_state_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.terraform_runner_service_account.email}"
}

resource "google_project_iam_member" "terraform_runner_service_account_creator" {
  project = var.project
  role    = "roles/iam.serviceAccountCreator"
  member  = "serviceAccount:${google_service_account.terraform_runner_service_account.email}"
}

# For Claude Code
resource "google_service_account" "claude_code_service_account" {
  account_id   = "claude-code-user"
  display_name = "Claude CodeがVertex AIを利用するためのサービスアカウント"
  project      = var.project
}

resource "google_project_iam_member" "claude_code_aiplatform_user" {
  project = var.project
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.claude_code_service_account.email}"
}

resource "google_project_iam_member" "claude_code_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.claude_code_service_account.email}"
}
