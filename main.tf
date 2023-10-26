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
    project = length(var.storage_project_id) > 0 ? var.storage_project_id : var.project_id
    name          = "${var.resource_prefix}-tfstate-storage"
    location      = var.storage_bucket_location
    versioning {
        enabled = true
    }
}

#Todo: allow for other TF backends than gcs
resource "google_cloudbuild_trigger" "my-repo-trigger" {
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  name          = "${var.resource_prefix}-repo-main-trigger"
  trigger_template {
    branch_name = "^main$"
    repo_name   = google_sourcerepo_repository.my-repo.name
  }
  build {
      source {
      # we need both, repo_sorce AND trigger template
      repo_source {
          repo_name   = google_sourcerepo_repository.my-repo.name
          branch_name = "^main$"
      }
    }
      timeout = "600s"
      step {
      name   = "ubuntu"
      script = <<EOF
        #!/usr/bin/bash
        ls -l 
        #echo "terraform {backend "gcs" {}}" > backend.tf
      EOF
      }
      step {
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["init", "-input=false",
                "-backend-config=bucket=${trimprefix(google_storage_bucket.tf-state-bucket.url,"gs://")}"]
        id = "tf init"
      }
      step {
        id = "tf plan"
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["plan", "-input=false",  "-out=/workspace/plan.out"]
      }
      step {
        id = "tf apply"
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["apply", "-input=false","/workspace/plan.out"]
      }
  }  
}