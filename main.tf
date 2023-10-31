module "service-accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  count = var.create_sa_for_codebuild ? 1 : 0
  project_id = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  version = "4.2.2"
  description = "SA for Codebuild Pipeline"
  names         = ["${var.resource_prefix}-sa"]
  project_roles = []
}

locals {
  sa_roles = [
    "roles/iam.serviceAccountTokenCreator",
    "roles/cloudbuild.serviceAgent"
  ]
}
resource "google_project_iam_member" "project" {
  count = var.create_sa_for_codebuild ? length(local.sa_roles) : 0
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  role    = local.sa_roles[count.index]
  member = "serviceAccount:${module.service-accounts[0].email}"
}

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

resource "google_sourcerepo_repository_iam_member" "sa_access" {
  count = var.create_sa_for_codebuild ? 1 : 0
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.reader"
  member = "serviceAccount:${module.service-accounts[0].email}"
}

resource "google_storage_bucket" "tf-state-bucket" {
    project = length(var.storage_project_id) > 0 ? var.storage_project_id : var.project_id
    name          = "${var.resource_prefix}-tfstate-storage"
    location      = var.storage_bucket_location
    versioning {
        enabled = true
    }
}

resource "google_storage_bucket_iam_member" "tf-state-bucket-member" {
  count = var.create_sa_for_codebuild ? 1 : 0
  bucket = google_storage_bucket.tf-state-bucket.name
  role = "roles/storage.objectUser"
  member = "serviceAccount:${module.service-accounts[0].email}"
}

#Todo: allow for other TF backends than gcs
resource "google_cloudbuild_trigger" "my-repo-trigger" {
  project = length(var.repo_project_id) > 0 ? var.repo_project_id : var.project_id
  name          = "${var.resource_prefix}-repo-main-trigger"
  trigger_template {
    branch_name = "^main$"
    repo_name   = google_sourcerepo_repository.my-repo.name
  }
#   service_account = module.service-accounts[0].service_account.id
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
      id = "create tf backend config"
      name   = "ubuntu"
      script = <<EOT
        echo 'terraform {\n backend "gcs" { \n }\n }' > backend.tf
      EOT
      }
      step {
      id = "debug tf backend"
      name   = "ubuntu"
      script = "ls -l; cat backend.tf"
      }
      step {
      id = "gcloud whoami"
      name   = "gcr.io/cloud-builders/gcloud"
      args = ["auth", "list"]
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