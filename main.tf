resource "google_sourcerepo_repository" "my-repo" {
  project = var.repo_project_id
  name = var.repo_name
}

resource "google_sourcerepo_repository_iam_member" "editors" {
  count   = length(var.repo_writers)
  project = var.repo_project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.writer"
  member  = element(var.repo_writers, count.index)
}