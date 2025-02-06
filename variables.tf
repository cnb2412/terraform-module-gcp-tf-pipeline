variable "project_id" {
  description = <<EOF
    "The ID of the project where all required IaC ressources will be created,
    e.g. the repo, the code build pipeline, tf storage account, etc."
  EOF
  type        = string
}

variable "location" {
  description = "The Cloud Build location for the trigger. Default europe-north1"
  default = "europe-west1"
  type = string
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

variable "storage_bucket_location" {
  description = "The location of the TF state bucket."
  type        = string
  default = "EUROPE-WEST3"
}

variable "tf_version" {
  description = "The terraform version, which should be used in the pipeline."
  type        = string
  default = "1.10"
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

variable "create_test" {
  default = true
  type = bool
  description = "Creates all ressources for iac pipeline to  deploy to test stage. Default true."
}

variable "create_prod" {
  default = true
  type = bool
  description = "Creates all ressources for iac pipeline to  deploy to Prod stage. Default true."
}

#### Config for test env pipeline
variable "trigger_branch" {
  default = "master"
  type = string
  description = "Branch by which the pipeline is triggerend, whenn committed to. Default master."
}

variable "deployment_project_id_test" {
  description = "The ID of the project where the IaC ressources should be deployed to for test env."
  type        = string
  default = ""
}

variable "tf_worksapce_test" {
  type = string
  description = "The name of the TF that should be used in pipeline for test env. Default none"
  default = ""
}

#### Config for prod env pipeline
variable "deployment_project_id_prod" {
  description = "The ID of the project where the IaC ressources should be deployed to for prod env."
  type        = string
  default = ""
}

variable "tf_worksapce_prod" {
  type = string
  description = "The name of the TF that should be used in pipeline for prod env. Default none"
  default = ""
}
