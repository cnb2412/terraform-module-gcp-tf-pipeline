data "google_project" "iac_project" {
    project_id = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
}