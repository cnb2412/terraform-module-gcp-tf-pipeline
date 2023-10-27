variable "project_id" {
  description = <<EOF
    "The ID of the project where all required ressources will be created. 
    If configured repo_project_id, storage_project_id should not be configured."
  EOF
  type        = string
  default = ""
}

variable "repo_project_id" {
  description = "The ID of the project where the repo will be created."
  type        = string
  default = ""
}

variable "resource_prefix" {
  description = "The name for the resources. A resource type postfix is appended to the individual ressources."
  type        = string
}

variable "repo_writers" {
  description = "Optional list of IAM-format members to set as source repo writer."
  type        = list(string)
  default     = []
}

variable "storage_project_id" {
  description = "The ID of the project where the repo will be created"
  type        = string
  default = ""
}

variable "storage_bucket_location" {
  description = "The location of the TF state bucket."
  type        = string
  default = "EUROPE-WEST3"
}

variable "tf_version" {
  description = "The terraform version, which should be used in the pipeline."
  type        = string
  default = "1.6.2"
}

variable "tf_backend" {
    description = "Which Backend should be used for TF. Currently only GCP Storageaccount is supported."  
    type        = string
    default = "gcs"
    validation {
        condition     = contains(["gcs"], var.tf_backend)
        error_message = "Currently only GCP Storageaccount is supported."
  } 
}

variable "create_sa_for_codebuild" {
    description = "Should a dedicated service account for the codebuild pipeline be created."
    type = bool
    default = true
}
