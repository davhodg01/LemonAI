terraform {
  backend "gcs" {
    bucket  = "lemonai-state-nimble-factor-478021-b4"
    prefix  = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# Static Public IP
resource "google_compute_address" "static_ip" {
  name = var.static_ip_name
  depends_on = [google_project_service.apis]
}

# Firewall Rules
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.network_tag]
}

resource "google_compute_firewall" "allow_ssh_admin" {
  name    = "allow-ssh-admin"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.admin_ssh_cidr]
  target_tags   = [var.network_tag]
}

# Explicit deny rules are implied by egress/ingress defaults, but we ensure no other ports are open by NOT adding rules for them.
# The default network usually allows internal traffic and ICMP. 
# We rely on the VM only listening on 443 and 22 explicitly.
