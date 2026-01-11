# Enable IAM Credentials API
resource "google_project_service" "iam_credentials" {
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

# Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
}

# Grant Editor Role to the Service Account
resource "google_project_iam_member" "github_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Grant Storage Admin (for State Bucket management)
resource "google_project_iam_member" "github_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

# Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  description                        = "OIDC Provider for GitHub Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "assertion.repository == '${var.github_repo}'"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions to Impersonate the Service Account
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/subject/repo:${var.github_repo}:ref:refs/heads/main"
}
