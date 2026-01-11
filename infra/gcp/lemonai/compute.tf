# Service Account
resource "google_service_account" "lemon_sa" {
  account_id   = "lemonai-sa"
  display_name = "LemonAI Service Account"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.lemon_sa.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.lemon_sa.email}"
}

# VM Instance
resource "google_compute_instance" "vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.network_tag]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = google_service_account.lemon_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/scripts/startup.sh", {
      SWAP_SIZE       = var.swap_size_gb
      BASIC_AUTH_USER = var.basic_auth_user
      BASIC_AUTH_PASS = var.basic_auth_pass
      STATIC_IP       = google_compute_address.static_ip.address
    })
  }

  metadata_startup_script = null # We use the metadata key directly above
}
