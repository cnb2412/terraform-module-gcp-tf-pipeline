resource "google_sourcerepo_repository" "my-repo" {
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  name = "${var.resource_prefix}-repo"
}

resource "google_sourcerepo_repository_iam_member" "editors" {
  count   = length(var.repo_writers)
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.writer"
  member  = element(var.repo_writers, count.index)
}

resource "google_storage_bucket" "tf-state-bucket" {
    project = length(var.storage_project_id) > 0 ? var.repo_project_id : var.project_id
    name          = "${var.resource_prefix}-tfstate-storage"
    location      = var.storage_bucket_location
    versioning {
        enabled = true
    }
}