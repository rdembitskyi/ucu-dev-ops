output "gcs_bucket_url" {
  description = "The URL of the GCS bucket created."
  value       = google_storage_bucket.app_bucket.url
}

output "bigquery_dataset_id" {
  description = "The full ID of the BigQuery dataset created."
  value       = google_bigquery_dataset.main_db.id
}

output "vm_instance_name" {
  description = "The name of the Compute Engine VM instance created."
  value       = google_compute_instance.main_vm.name
}

output "vm_instance_public_ip" {
  description = "The public IP address of the VM instance."
  value       = google_compute_instance.main_vm.network_interface[0].access_config[0].nat_ip
}