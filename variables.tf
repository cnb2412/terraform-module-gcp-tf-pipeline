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