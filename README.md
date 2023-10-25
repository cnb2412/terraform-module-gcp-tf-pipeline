# Terraform module to create a CICD pipline Terraform pipeline

This module allows for creating a CICD pipline on GCP to develop and deploy
IaC.

## Usage

Simple usage is as follows:

```hcl
module "cicd-pipeline" {
  source = "git::https://github.com/cnb2412/terraform-module-gcp-tf-pipeline.git"
}
```

## Features

The Project Factory module will take the following actions:

1. Create a source repo on GCP porject

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_repo_name"></a> [repo\_name](#input\_repo\_name) | The name for the source repo | `string` | n/a | yes |
| <a name="input_repo_project_id"></a> [repo\_project\_id](#input\_repo\_project\_id) | The ID of the project where the repo will be created | `string` | n/a | yes |
<!-- END_TF_DOCS -->