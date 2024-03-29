module "service-account-test" {
  count = var.create_test ? 1 : 0
  source  = "terraform-google-modules/service-accounts/google"
  project_id = var.project_id
  version = "4.2.2"
  description = "SA for Codebuild Pipeline (Test env)"
  names         = ["${var.resource_prefix}-sa-t"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter"
  ]
}

module "service-account-prod" {
  count = var.create_prod ? 1 : 0
  source  = "terraform-google-modules/service-accounts/google"
  project_id = var.project_id
  version = "4.2.2"
  description = "SA for Codebuild Pipeline (Prod env)"
  names         = ["${var.resource_prefix}-sa-p"]
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter"
  ]
}

resource "google_sourcerepo_repository" "my-repo" {
  project = var.project_id
  name = "${var.resource_prefix}-repo"
}

resource "google_sourcerepo_repository_iam_member" "editors" {
  count   = length(var.repo_writers)
  project = var.project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.writer"
  member  = element(var.repo_writers, count.index)
}
resource "google_sourcerepo_repository_iam_member" "repo_reader_test" {
  count   = var.create_test ? 1 : 0
  project = var.project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.reader"
  member  = "serviceAccount:${module.service-account-test[0].email}"
}
resource "google_sourcerepo_repository_iam_member" "repo_reader_prod" {
  count   = var.create_prod ? 1 : 0
  project = var.project_id
  repository = google_sourcerepo_repository.my-repo.name
  role    = "roles/source.reader"
  member  = "serviceAccount:${module.service-account-prod[0].email}"
}

##permission for service account, with wich the pipeline starts <id>@cloudbuild.gserviceaccount.com
locals {
  sa_roles = [
    "roles/cloudbuild.builds.builder",
    "roles/logging.logWriter"
  ]
}
resource "google_project_iam_member" "cloudbuild_sa_roles" {
  count = length(local.sa_roles)
  project = var.project_id
  role    = local.sa_roles[count.index]
  member = "serviceAccount:${data.google_project.iac_project.number}@cloudbuild.gserviceaccount.com"
}

##permission for service account, with is used within the pipeline, i.e. sa created in this script
locals {
  sa_used_in_cb_roles = [
    "roles/owner"
  ]
}
resource "google_project_iam_member" "sa_assigend_in_cb_roles" {
  count = var.create_test ? length(local.sa_used_in_cb_roles) : 0 
  project = var.deployment_project_id_test
  role    = local.sa_used_in_cb_roles[count.index]
  member = "serviceAccount:${module.service-account-test[0].email}"
}
resource "google_project_iam_member" "sa_assigend_in_cb_prod_roles" {
  count = var.create_prod ? length(local.sa_used_in_cb_roles) : 0 
  project = var.deployment_project_id_prod
  role    = local.sa_used_in_cb_roles[count.index]
  member = "serviceAccount:${module.service-account-prod[0].email}"
}

## storage bucket for tf states
resource "google_storage_bucket" "tf-state-bucket" {
    project = var.project_id
    name          = "${var.resource_prefix}-tfstate-storage"
    location      = var.storage_bucket_location
    force_destroy = true
    versioning {
        enabled = true
    }
}

resource "google_storage_bucket_iam_member" "tf-state-bucket-member" {
  count   = var.create_test ? 1 : 0
  bucket = google_storage_bucket.tf-state-bucket.name
  role = "roles/storage.objectUser"
  member = "serviceAccount:${module.service-account-test[0].email}"
}
resource "google_storage_bucket_iam_member" "tf-state-bucket-member-prod" {
  count = var.create_prod ? 1 : 0
  bucket = google_storage_bucket.tf-state-bucket.name
  role = "roles/storage.objectUser"
  member = "serviceAccount:${module.service-account-prod[0].email}"
}

#Todo: allow for other TF backends than gcs
resource "google_cloudbuild_trigger" "test_stage_trigger" {
  count = var.create_test ? 1 : 0
  project = var.project_id
  name          = "${var.resource_prefix}-test-env-trigger"
  description = "Cloud Build trigger for ${var.resource_prefix} deployment to test env."
  location = var.location
  trigger_template {
    branch_name = "^${var.trigger_branch}$"
    repo_name   = google_sourcerepo_repository.my-repo.name
  }
  service_account = module.service-account-test[0].service_account.id
  build {
      source {
      # we need both, repo_sorce AND trigger template
      repo_source {
          repo_name   = google_sourcerepo_repository.my-repo.name
          branch_name = "^${var.trigger_branch}$"
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
        id = "gcloud whoami"
        name   = "gcr.io/cloud-builders/gcloud"
        args = ["auth", "list"]
      }
      step {
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["init", "-input=false",
                "-backend-config=bucket=${trimprefix(google_storage_bucket.tf-state-bucket.url,"gs://")}",
                "-backend-config=prefix=test_env"]
        id = "tf init"
      }
      step {
        id = "tf plan"
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["plan", "-input=false",  "-out=/workspace/plan.out"]
        env = [
          length(var.deployment_project_id_test) > 0 ? "GOOGLE_PROJECT=${var.deployment_project_id_test}" : "",
          length(var.tf_worksapce_test) > 0 ? "TF_WORKSPACE=${var.tf_worksapce_test}" : ""
        ]
        
        
      }
      step {
        id = "tf apply"
        name = "hashicorp/terraform:${var.tf_version}"
        args = ["apply", "-input=false","/workspace/plan.out"]
        env = [
          length(var.deployment_project_id_test) > 0 ? "GOOGLE_PROJECT=${var.deployment_project_id_test}" : "",
          length(var.tf_worksapce_test) > 0 ? "TF_WORKSPACE=${var.tf_worksapce_test}" : ""
        ]
      }
      options {
    logging = "CLOUD_LOGGING_ONLY"
  }
  }  
}

resource "google_cloudbuild_trigger" "prod_stage_trigger" {
  count = var.create_prod ? 1 : 0
  project = var.project_id
  name          = "${var.resource_prefix}-prod-env-trigger"
  description = "Cloud Build trigger for ${var.resource_prefix} deployment to Prod env."
  location = var.location
  service_account = module.service-account-prod[0].service_account.id
  source_to_build {
    uri       = google_sourcerepo_repository.my-repo.url
    ref       = "refs/heads/${var.trigger_branch}"
    repo_type = "CLOUD_SOURCE_REPOSITORIES"
  } 
  build {
    source {
      repo_source {
          repo_name   = google_sourcerepo_repository.my-repo.name
          branch_name = "^${var.trigger_branch}$"
      }
    }
    timeout = "600s"
    options {
      logging = "CLOUD_LOGGING_ONLY"
    }
    step {
      id = "create tf backend config"
      name   = "ubuntu"
      script = <<EOT
        echo 'terraform {\n backend "gcs" { \n }\n }' > backend.tf
      EOT
    }
    step {
        id = "gcloud whoami"
        name   = "gcr.io/cloud-builders/gcloud"
        args = ["auth", "list"]
    }
    step {
      name = "hashicorp/terraform:${var.tf_version}"
      args = ["init", "-input=false",
              "-backend-config=bucket=${trimprefix(google_storage_bucket.tf-state-bucket.url,"gs://")}",
              "-backend-config=prefix=test_prod"]
      id = "tf init"
    }
    step {
      id = "tf plan"
      name = "hashicorp/terraform:${var.tf_version}"
      args = ["plan", "-input=false",  "-out=/workspace/plan.out"]
      env = [
          length(var.deployment_project_id_prod) > 0 ? "GOOGLE_PROJECT=${var.deployment_project_id_prod}" : "",
          length(var.tf_worksapce_prod) > 0 ? "TF_WORKSPACE=${var.tf_worksapce_prod}" : ""
      ]
    }
    step {
      id = "tf apply"
      name = "hashicorp/terraform:${var.tf_version}"
      args = ["apply", "-input=false","/workspace/plan.out"]
      env = [
        length(var.deployment_project_id_prod) > 0 ? "GOOGLE_PROJECT=${var.deployment_project_id_prod}" : "",
        length(var.tf_worksapce_prod) > 0 ? "TF_WORKSPACE=${var.tf_worksapce_prod}" : ""
      ]
    }
  }
}