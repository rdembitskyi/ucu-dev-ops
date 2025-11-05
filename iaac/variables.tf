variable "gcp_project_id" {
  description = "The GCP project ID to deploy resources into."
  type        = string
  default     = "spring-melody-472217-a1"
}

variable "gcp_region" {
  description = "The GCP region to create resources in."
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "A unique name for the project to prefix resources."
  type        = string
  default     = "gcp-homework-project"
}