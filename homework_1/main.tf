data "google_compute_image" "debian_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

# --- Resource 1: GCS Bucket ---
resource "google_storage_bucket" "app_bucket" {
  name          = "${var.project_name}-app-bucket-${random_id.suffix.hex}"
  location      = var.gcp_region
  force_destroy = true

  labels = {
    project = var.project_name
  }
}

# --- Resource 2: BigQuery Dataset ---
resource "google_bigquery_dataset" "main_db" {
  dataset_id = replace(var.project_name, "-", "_")
  location   = var.gcp_region

  labels = {
    project = var.project_name
  }
}

# --- Resource 3: Compute Engine VM ---
resource "google_compute_instance" "main_vm" {
  name         = "${var.project_name}-vm"
  machine_type = "e2-micro"
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  # This attaches the VM to the 'default' VPC network and assigns a public IP address.
  network_interface {
    network = "default"
    access_config {
    }
  }

  labels = {
    project = var.project_name
  }
}

# Generates a random suffix to ensure the GCS bucket name is unique.
resource "random_id" "suffix" {
  byte_length = 8
}