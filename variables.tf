variable "repo_project_id" {
  description = "The ID of the project where the repo will be created"
  type        = string
}

variable "repo_name" {
  description = "The name for the source repo"
  type        = string
}

variable "repo_writers" {
  description = "Optional list of IAM-format members to set as source repo writer."
  type        = list(string)
  default     = []
}