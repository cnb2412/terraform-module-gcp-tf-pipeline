resource "google_sourcerepo_repository" "my-repo" {
  project = var.repo_project_id
  name = var.repo_name
}