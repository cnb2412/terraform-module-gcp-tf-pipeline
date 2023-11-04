# Terraform module to create a CICD pipline Terraform pipeline

This module allows for creating multistate CICD piplines on GCP to develop and deploy
IaC.

It follows a trunk-based approach. That is, it creates a pipeline that is triggered by a commit to the main branch of a git repo and deploys automatically to a test env. Furthermore, it creates a second pipeline tht is triggered manually to deloy the same branch to a prod env.

## Usage

Simple usage is as follows:

```hcl
module "cicd-pipeline" {
  source = "git::https://github.com/cnb2412/terraform-module-gcp-tf-pipeline.git"
  resource_prefix = "mail-reflector-iac"
  project_id = "gcp-project"
  repo_writers = ["user:user@example.com"]
  storage_bucket_location = "europe-north1"
}
```

## Features

The Project Factory module will take the following actions:

1. Create a source repo on GCP porject
1. Create a dedicated service account for code build to deploy IaC ressources
1. Storage bucket for TF state file
1. Cloud Build Trigger and build config to deploy iac ressources
1.1 Create env var in build config TF_VAR_project_id to use the project id in builds


<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | "The ID of the project where all required ressources will be created. <br>    If configured repo\_project\_id, storage\_project\_id should not be configured." | `string` | `""` | no |
| <a name="input_repo_project_id"></a> [repo\_project\_id](#input\_repo\_project\_id) | The ID of the project where the repo will be created. | `string` | `""` | no |
| <a name="input_repo_writers"></a> [repo\_writers](#input\_repo\_writers) | Optional list of IAM-format members to set as source repo writer. | `list(string)` | `[]` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | The name for the resources. A resource type postfix is appended to the individual ressources. | `string` | n/a | yes |
| <a name="input_storage_bucket_location"></a> [storage\_bucket\_location](#input\_storage\_bucket\_location) | The location of the TF state bucket. | `string` | `"EUROPE-WEST3"` | no |
| <a name="input_storage_project_id"></a> [storage\_project\_id](#input\_storage\_project\_id) | The ID of the project where the repo will be created | `string` | `""` | no |
| <a name="input_tf_backend"></a> [tf\_backend](#input\_tf\_backend) | Which Backend should be used for TF. Currently only GCP Storageaccount is supported. | `string` | `"gcs"` | no |
| <a name="input_tf_version"></a> [tf\_version](#input\_tf\_version) | The terraform version, which should be used in the pipeline. | `string` | `"1.6.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | n/a |
<!-- END_TF_DOCS -->