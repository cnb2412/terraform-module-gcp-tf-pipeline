# Terraform module to create a CICD pipline Terraform pipeline

This module allows for creating a CICD pipline on GCP to develop and deploy
IaC.

## Usage

Simple usage is as follows:

```hcl
module "cicd-pipeline" {
  source  = ""
  version = "~> 14.4"
}
```

## Features

The Project Factory module will take the following actions:

1. Create a source repo on GCP porject