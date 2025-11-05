terraform {
  backend "gcs" {
    bucket = "rd-ucu-bucket"

    # The path to the state file within the GCS bucket.
    prefix = "ucu/devops/terraform/state"
  }
}