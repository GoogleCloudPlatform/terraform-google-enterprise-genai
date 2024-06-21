# Deploying on top of existing Foundation v.4.0.0

## Overview

To deploy a simple machine learning application, you must first have a [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) instance set up. The following steps will guide you through the additional configurations required on top of the foundation.

## Requirements

### Code

- [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) deployed until at least step `4-projects`.
- You must have role **Service Account User** (`roles/iam.serviceAccountUser`) on the [Terraform Service Accounts](https://github.com/terraform-google-modules/terraform-example-foundation/blob/master/docs/GLOSSARY.md#terraform-service-accounts) created in the foundation [Seed Project](https://github.com/terraform-google-modules/terraform-example-foundation/blob/master/docs/GLOSSARY.md#seed-project).
  The Terraform Service Accounts have the permissions to deploy each step of the foundation. Service Accounts:
  - `sa-terraform-bootstrap@<SEED_PROJECT_ID>.iam.gserviceaccount.com`.
  - `sa-terraform-env@<SEED_PROJECT_ID>.iam.gserviceaccount.com`
  - `sa-terraform-net@<SEED_PROJECT_ID>.iam.gserviceaccount.com`
  - `sa-terraform-proj@<SEED_PROJECT_ID>.iam.gserviceaccount.com`

### Software

Install the following dependencies:

- [Google Cloud SDK](https://cloud.google.com/sdk/install) version 469.0.0 or later.
- [Terraform](https://www.terraform.io/downloads.html) version 1.7.5 or later.

### Google Cloud SDK Configuration

Terraform must have Application Default Credentials configured, to configure it run:

```bash
gcloud auth application-default login
```

## Directory Layout and Terraform Initialization

For these instructions we assume that:

- The foundation was deployed using Cloud Build.
- Every repository, excluding the policies repositories, should be on the `production` branch and `terraform init` should be executed in each one.
- The following layout should exists in your local environment since you will need to make changes in these steps.
If you do not have this layout, please checkout the source repositories for the foundation steps following this layout.

    ```text
    gcp-bootstrap
    gcp-environments
    gcp-networks
    gcp-org
    gcp-policies
    gcp-projects
    ```

- Also checkout the [terraform-google-enterprise-genai](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai) repository at the same level.

The final layout should look like this:

```text
gcp-bootstrap
gcp-environments
gcp-networks
gcp-org
gcp-policies
gcp-projects
terraform-google-enterprise-genai
```

## Policies

### Update `gcloud terraform vet` policies

the first step is to update the `gcloud terraform vet` policies constraints to allow usage of the APIs needed by the Blueprint and add more policies.
The constraints are located in the repository:

- `gcp-policies`

**IMPORTANT:** Please note that the steps below are assuming you are checked out on `terraform-google-enterprise-genai/`.

- Copy `cmek_settings.yaml` from this repository to the policies repository:

``` bash
cp policy-library/policies/constraints/cmek_settings.yaml ../gcp-policies/policies/constraints/cmek_settings.yaml
```

- Copy `network_enable_firewall_logs.yaml` from this repository to the policies repository:

``` bash
cp policy-library/policies/constraints/network_enable_firewall_logs.yaml ../gcp-policies/policies/constraints/network_enable_firewall_logs.yaml
```

- Copy `require_dnssec.yaml` from this repository to the policies repository:

``` bash
cp policy-library/policies/constraints/require_dnssec.yaml ../gcp-policies/policies/constraints/require_dnssec.yaml
```

- On `gcp-policies` change `serviceusage_allow_basic_apis.yaml` and add the following apis:

```yaml
     - "aiplatform.googleapis.com"
     - "bigquerymigration.googleapis.com"
     - "bigquerystorage.googleapis.com"
     - "containerregistry.googleapis.com"
     - "dataflow.googleapis.com"
     - "dataform.googleapis.com"
     - "deploymentmanager.googleapis.com"
     - "notebooks.googleapis.com"
     - "composer.googleapis.com"
     - "containerscanning.googleapis.com"
```

Add files to tracked on `gcp-policies` repository, commit and push the code:

```bash
cd ../gcp-policies

git add policies/constraints/*.yaml
git commit -m "Add ML policies constraints"
git push origin $(git branch --show-current)
```

## 1-org: Create Machine Learning Organization Policies and Organization Level Keys

This step corresponds to modifications made to `1-org` step on foundation.

**IMPORTANT:** Please note that the steps below are assuming you are checked out on `terraform-google-enterprise-genai/` and that `gcp-org` repository is checked out on `production` branch.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy Machine Learning modules from this repo to `gcp-org` repository.

```bash
cp -r 1-org/modules/ml_kms_keyring ../gcp-org/modules
cp -r 1-org/modules/ml-org-policies ../gcp-org/modules
```

- Create `ml_ops_org_policy.tf` file on `gcp-org/envs/shared` path:

```bash
cp docs/assets/terraform/1-org/ml_ops_org_policy.tf ../gcp-org/envs/shared
```

- Create `ml_key_rings.tf` file on `gcp-org/envs/shared` path:

```bash
cp docs/assets/terraform/1-org/ml_key_rings.tf ../gcp-org/envs/shared
```

- Edit `gcp-org/envs/shared/remote.tf` and add the following value to `locals`:

```terraform
projects_step_terraform_service_account_email = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
```

- Edit `gcp-org/envs/shared/variables.tf` and add the following variables:

```terraform
variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "ml-org-keyring"
}
```

- Edit `gcp-org/envs/shared/outputs.tf` and add the following output:

```terraform
output "key_rings" {
  description = "Keyring Names created"
  value       = module.kms_keyring.key_rings
}
```

Add files to git on `gcp-org`, commit and push code:

```bash
cd ../gcp-org

git add .

git commit -m "Add ML org policies and Org-level key"
git push origin production
```

## 2-environment: Create environment level logging keys, logging project and logging bucket

This step corresponds to modifications made to `2-environment` step on foundation.

Please note that the steps below are assuming you are checked out on `terraform-google-enterprise-genai/`.

```bash
cd ../terraform-google-enterprise-genai
```

### `development` branch

- Go to `gcp-environments` repository, and check out on `development` branch.

```bash
cd ../gcp-environments

git checkout development
```

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy Machine Learning modules from this repo to `gcp-environments` repository.

```bash
cp -r 2-environments/modules/ml_kms_keyring ../gcp-environments/modules
```

- Create `ml_key_rings.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_key_rings.tf ../gcp-environments/modules/env_baseline
```

- Create `ml_logging.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_logging.tf ../gcp-environments/modules/env_baseline
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following variables:

```terraform
variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "ml-env-keyring"
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "kms_prevent_destroy" {
  description = "Wheter to prevent keyring and keys destruction. Must be set to false if the user wants to disable accidental terraform deletions protection."
  type        = bool
  default     = true
}

variable "gcs_bucket_prefix" {
  description = "Bucket Prefix"
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of environment logging bucket"
  type        = string
  default     = "us-central1"
}

variable "gcs_logging_retention_period" {
  description = "Retention configuration for environment logging bucket"
  type = object({
    is_locked             = bool
    retention_period_days = number
  })
  default = null
}

variable "gcs_logging_key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following field to `project_budget` specification:

```terraform
logging_budget_amount                       = optional(number, 1000)
logging_alert_spent_percents                = optional(list(number), [1.2])
logging_alert_pubsub_topic                  = optional(string, null)
logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
```

This will result in a variable similar to the variable specified below:

```terraform
variable "project_budget" {
  description = <<EOT
  Budget configuration for projects.
  budget_amount: The amount to use as the budget.
  alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
  alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
  alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
  EOT
  type = object({
    base_network_budget_amount                  = optional(number, 1000)
    base_network_alert_spent_percents           = optional(list(number), [1.2])
    base_network_alert_pubsub_topic             = optional(string, null)
    base_network_budget_alert_spend_basis       = optional(string, "FORECASTED_SPEND")
    restricted_network_budget_amount            = optional(number, 1000)
    restricted_network_alert_spent_percents     = optional(list(number), [1.2])
    restricted_network_alert_pubsub_topic       = optional(string, null)
    restricted_network_budget_alert_spend_basis = optional(string, "FORECASTED_SPEND")
    monitoring_budget_amount                    = optional(number, 1000)
    monitoring_alert_spent_percents             = optional(list(number), [1.2])
    monitoring_alert_pubsub_topic               = optional(string, null)
    monitoring_budget_alert_spend_basis         = optional(string, "FORECASTED_SPEND")
    secret_budget_amount                        = optional(number, 1000)
    secret_alert_spent_percents                 = optional(list(number), [1.2])
    secret_alert_pubsub_topic                   = optional(string, null)
    secret_budget_alert_spend_basis             = optional(string, "FORECASTED_SPEND")
    kms_budget_amount                           = optional(number, 1000)
    kms_alert_spent_percents                    = optional(list(number), [1.2])
    kms_alert_pubsub_topic                      = optional(string, null)
    kms_budget_alert_spend_basis                = optional(string, "FORECASTED_SPEND")
    logging_budget_amount                       = optional(number, 1000)
    logging_alert_spent_percents                = optional(list(number), [1.2])
    logging_alert_pubsub_topic                  = optional(string, null)
    logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
  })
  default = {}
}
```

- On `gcp-environments/modules/env_baseline/remote.tf` add the following value to `locals`:

```terraform
projects_step_terraform_service_account_email = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
```

- On `gcp-environments/envs/development/outputs.tf` add the following outputs:

```terraform
output "env_log_project_id" {
  description = "Project ID of the environments log project"
  value       = module.env.env_logs_project_id
}

output "env_log_project_number" {
  description = "Project Number of the environments log project"
  value       = module.env.env_logs_project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = module.env.env_log_bucket_name
}

output "env_kms_project_number" {
  description = "Project Number for environment Cloud Key Management Service (KMS)."
  value       = module.env.env_kms_project_number
}

output "key_rings" {
  description = "Keyring Names created"
  value       = module.env.key_rings
}
```

- On `gcp-environments/modules/env_baseline/outputs.tf` add the following outputs:

```terraform
output "key_rings" {
  description = "Keyring Names created"
  value       = module.kms_keyring.key_rings
}

output "env_kms_project_number" {
  description = "Project number for environment Cloud Key Management Service (KMS)."
  value       = module.env_kms.project_number
}

output "env_logs_project_id" {
  description = "Project ID for environment logging."
  value       = module.env_logs.project_id
}

output "env_logs_project_number" {
  description = "Project number for environment logging."
  value       = module.env_logs.project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = google_storage_bucket.log_bucket.name
}
```

- Commit and push files to git repo.

```bash
cd ../gcp-environments

git add .

git commit -m "Create env-level keys and env-level logging"

git push origin development
```

### `nonproduction` branch

- Go to `gcp-environments` repository, and check out on `nonproduction` branch.

```bash
cd ../gcp-environments

git checkout nonproduction
```

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy Machine Learning modules from this repo to `gcp-environments` repository.

```bash
cp -r 2-environments/modules/ml_kms_keyring ../gcp-environments/modules
```

- Create `ml_key_rings.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_key_rings.tf ../gcp-environments/modules/env_baseline
```

- Create `ml_logging.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_logging.tf ../gcp-environments/modules/env_baseline
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following variables:

```terraform
variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "ml-env-keyring"
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "kms_prevent_destroy" {
  description = "Wheter to prevent keyring and keys destruction. Must be set to false if the user wants to disable accidental terraform deletions protection."
  type        = bool
  default     = true
}

variable "gcs_bucket_prefix" {
  description = "Bucket Prefix"
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of environment logging bucket"
  type        = string
  default     = "us-central1"
}

variable "gcs_logging_retention_period" {
  description = "Retention configuration for environment logging bucket"
  type = object({
    is_locked             = bool
    retention_period_days = number
  })
  default = null
}

variable "gcs_logging_key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following field to `project_budget` specification:

```terraform
logging_budget_amount                       = optional(number, 1000)
logging_alert_spent_percents                = optional(list(number), [1.2])
logging_alert_pubsub_topic                  = optional(string, null)
logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
```

This will result in a variable similar to the variable specified below:

```terraform
variable "project_budget" {
  description = <<EOT
  Budget configuration for projects.
  budget_amount: The amount to use as the budget.
  alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
  alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
  alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
  EOT
  type = object({
    base_network_budget_amount                  = optional(number, 1000)
    base_network_alert_spent_percents           = optional(list(number), [1.2])
    base_network_alert_pubsub_topic             = optional(string, null)
    base_network_budget_alert_spend_basis       = optional(string, "FORECASTED_SPEND")
    restricted_network_budget_amount            = optional(number, 1000)
    restricted_network_alert_spent_percents     = optional(list(number), [1.2])
    restricted_network_alert_pubsub_topic       = optional(string, null)
    restricted_network_budget_alert_spend_basis = optional(string, "FORECASTED_SPEND")
    monitoring_budget_amount                    = optional(number, 1000)
    monitoring_alert_spent_percents             = optional(list(number), [1.2])
    monitoring_alert_pubsub_topic               = optional(string, null)
    monitoring_budget_alert_spend_basis         = optional(string, "FORECASTED_SPEND")
    secret_budget_amount                        = optional(number, 1000)
    secret_alert_spent_percents                 = optional(list(number), [1.2])
    secret_alert_pubsub_topic                   = optional(string, null)
    secret_budget_alert_spend_basis             = optional(string, "FORECASTED_SPEND")
    kms_budget_amount                           = optional(number, 1000)
    kms_alert_spent_percents                    = optional(list(number), [1.2])
    kms_alert_pubsub_topic                      = optional(string, null)
    kms_budget_alert_spend_basis                = optional(string, "FORECASTED_SPEND")
    logging_budget_amount                       = optional(number, 1000)
    logging_alert_spent_percents                = optional(list(number), [1.2])
    logging_alert_pubsub_topic                  = optional(string, null)
    logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
  })
  default = {}
}
```

- On `gcp-environments/modules/env_baseline/remote.tf` add the following value to `locals`:

```terraform
projects_step_terraform_service_account_email = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
```

- On `gcp-environments/envs/nonproduction/outputs.tf` add the following outputs:

```terraform
output "env_log_project_id" {
  description = "Project ID of the environments log project"
  value       = module.env.env_logs_project_id
}

output "env_log_project_number" {
  description = "Project Number of the environments log project"
  value       = module.env.env_logs_project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = module.env.env_log_bucket_name
}

output "env_kms_project_number" {
  description = "Project Number for environment Cloud Key Management Service (KMS)."
  value       = module.env.env_kms_project_number
}

output "key_rings" {
  description = "Keyring Names created"
  value       = module.env.key_rings
}
```

- On `gcp-environments/modules/env_baseline/outputs.tf` add the following outputs:

```terraform
output "key_rings" {
  description = "Keyring Names created"
  value       = module.kms_keyring.key_rings
}

output "env_kms_project_number" {
  description = "Project number for environment Cloud Key Management Service (KMS)."
  value       = module.env_kms.project_number
}

output "env_logs_project_id" {
  description = "Project ID for environment logging."
  value       = module.env_logs.project_id
}

output "env_logs_project_number" {
  description = "Project number for environment logging."
  value       = module.env_logs.project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = google_storage_bucket.log_bucket.name
}
```

- Commit and push files to git repo.

```bash
cd ../gcp-environments

git add .

git commit -m "Create env-level keys and env-level logging"

git push origin nonproduction
```

### `production` branch

- Go to `gcp-environments` repository, and check out on `production` branch.

```bash
cd ../gcp-environments

git checkout production
```

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy Machine Learning modules from this repo to `gcp-environments` repository.

```bash
cp -r 2-environments/modules/ml_kms_keyring ../gcp-environments/modules
```

- Create `ml_key_rings.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_key_rings.tf ../gcp-environments/modules/env_baseline
```

- Create `ml_logging.tf` file on `gcp-environments/modules/env_baseline` path:

```bash
cp docs/assets/terraform/2-environments/ml_logging.tf ../gcp-environments/modules/env_baseline
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following variables:

```terraform
variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "ml-env-keyring"
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "kms_prevent_destroy" {
  description = "Wheter to prevent keyring and keys destruction. Must be set to false if the user wants to disable accidental terraform deletions protection."
  type        = bool
  default     = true
}

variable "gcs_bucket_prefix" {
  description = "Bucket Prefix"
  type        = string
  default     = "bkt"
}

variable "gcs_logging_bucket_location" {
  description = "Location of environment logging bucket"
  type        = string
  default     = "us-central1"
}

variable "gcs_logging_retention_period" {
  description = "Retention configuration for environment logging bucket"
  type = object({
    is_locked             = bool
    retention_period_days = number
  })
  default = null
}

variable "gcs_logging_key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}
```

- On `gcp-environments/modules/env_baseline/variables.tf` add the following field to `project_budget` specification:

```terraform
logging_budget_amount                       = optional(number, 1000)
logging_alert_spent_percents                = optional(list(number), [1.2])
logging_alert_pubsub_topic                  = optional(string, null)
logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
```

This will result in a variable similar to the variable specified below:

```terraform
variable "project_budget" {
  description = <<EOT
  Budget configuration for projects.
  budget_amount: The amount to use as the budget.
  alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
  alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
  alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
  EOT
  type = object({
    base_network_budget_amount                  = optional(number, 1000)
    base_network_alert_spent_percents           = optional(list(number), [1.2])
    base_network_alert_pubsub_topic             = optional(string, null)
    base_network_budget_alert_spend_basis       = optional(string, "FORECASTED_SPEND")
    restricted_network_budget_amount            = optional(number, 1000)
    restricted_network_alert_spent_percents     = optional(list(number), [1.2])
    restricted_network_alert_pubsub_topic       = optional(string, null)
    restricted_network_budget_alert_spend_basis = optional(string, "FORECASTED_SPEND")
    monitoring_budget_amount                    = optional(number, 1000)
    monitoring_alert_spent_percents             = optional(list(number), [1.2])
    monitoring_alert_pubsub_topic               = optional(string, null)
    monitoring_budget_alert_spend_basis         = optional(string, "FORECASTED_SPEND")
    secret_budget_amount                        = optional(number, 1000)
    secret_alert_spent_percents                 = optional(list(number), [1.2])
    secret_alert_pubsub_topic                   = optional(string, null)
    secret_budget_alert_spend_basis             = optional(string, "FORECASTED_SPEND")
    kms_budget_amount                           = optional(number, 1000)
    kms_alert_spent_percents                    = optional(list(number), [1.2])
    kms_alert_pubsub_topic                      = optional(string, null)
    kms_budget_alert_spend_basis                = optional(string, "FORECASTED_SPEND")
    logging_budget_amount                       = optional(number, 1000)
    logging_alert_spent_percents                = optional(list(number), [1.2])
    logging_alert_pubsub_topic                  = optional(string, null)
    logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")
  })
  default = {}
}
```

- On `gcp-environments/modules/env_baseline/remote.tf` add the following value to `locals`:

```terraform
projects_step_terraform_service_account_email = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
```

- On `gcp-environments/envs/production/outputs.tf` add the following outputs:

```terraform
output "env_log_project_id" {
  description = "Project ID of the environments log project"
  value       = module.env.env_logs_project_id
}

output "env_log_project_number" {
  description = "Project Number of the environments log project"
  value       = module.env.env_logs_project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = module.env.env_log_bucket_name
}

output "env_kms_project_number" {
  description = "Project Number for environment Cloud Key Management Service (KMS)."
  value       = module.env.env_kms_project_number
}

output "key_rings" {
  description = "Keyring Names created"
  value       = module.env.key_rings
}
```

- On `gcp-environments/modules/env_baseline/outputs.tf` add the following outputs:

```terraform
output "key_rings" {
  description = "Keyring Names created"
  value       = module.kms_keyring.key_rings
}

output "env_kms_project_number" {
  description = "Project number for environment Cloud Key Management Service (KMS)."
  value       = module.env_kms.project_number
}

output "env_logs_project_id" {
  description = "Project ID for environment logging."
  value       = module.env_logs.project_id
}

output "env_logs_project_number" {
  description = "Project number for environment logging."
  value       = module.env_logs.project_number
}

output "env_log_bucket_name" {
  description = "Name of environment log bucket"
  value       = google_storage_bucket.log_bucket.name
}
```

- Commit and push files to git repo.

```bash
cd ../gcp-environments

git add .

git commit -m "Create env-level keys and env-level logging"

git push origin production
```

### `N.B.` Read this before continuing further

A logging project will be created in every environment (`development`, `non-production`, `production`) when running this code. This project contains a storage bucket for the purposes of project logging within its respective environment.  This requires the `cloud-storage-analytics@google.com` group permissions for the storage bucket.  Since foundations has more restricted security measures, a domain restriction constraint is enforced.  This restraint will prevent the google cloud-storage-analytics group to be added to any permissions.  In order for this terraform code to execute without error, manual intervention must be made to ensure everything applies without issue.

You must disable the contraint, assign the permission on the bucket and then apply the contraint again. This step-by-step presents you with two different options (`Option 1` and `Option 2`) and only one of them should be executed.

The first and the recommended option is making the changes by using `gcloud` cli, as described in `Option 1`.

`Option 2` is an alternative to `gcloud` cli and relies on Google Cloud Console.

#### Option 1: Use `gcloud` cli to disable/enable organization policy constraint

You will be doing this procedure for each environment (`development`, `non-production` & `production`)

##### `development` environment configuration

1. Configure the following variable below with the value of `gcp-environments` repository path.

    ```bash
    export GCP_ENVIRONMENTS_PATH=INSERT_YOUR_PATH_HERE
    ```

    Make sure your git is checked out to the development branch by running `git checkout development` on `GCP_ENVIRONMENTS_PATH`.

    ```bash
    (cd $GCP_ENVIRONMENTS_PATH && git checkout development)
    ```

2. Retrieve the bucket name and project id from terraform outputs.

    ```bash
    export ENV_LOG_BUCKET_NAME=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/development" output -raw env_log_bucket_name)
    export ENV_LOG_PROJECT_ID=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/development" output -raw env_log_project_id)
    ```

3. Validate the variable values.

    ```bash
    echo env_log_project_id=$ENV_LOG_PROJECT_ID
    echo env_log_bucket_name=$ENV_LOG_BUCKET_NAME
    ```

4. Reset your org policy for the logging project by running the following command.

    ```bash
    gcloud org-policies reset iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

5. Assign `roles/storage.objectCreator` role to `cloud-storage-analytics@google.com` group.

    ```bash
    gcloud storage buckets add-iam-policy-binding gs://$ENV_LOG_BUCKET_NAME --member="group:cloud-storage-analytics@google.com" --role="roles/storage.objectCreator"
    ```

    > Note: you might receive an error telling you that this is against an organization policy, this can happen because of the propagation time from the change made to the organization policy (propagation time is tipically 2 minutes, but can take 7 minutes or longer). If this happens, wait some minutes and try again

6. Delete the change made on the first step to the organization policy, this will make the project inherit parent policies.

    ```bash
    gcloud org-policies delete iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

##### `non-production` environment configuration

1. Configure the following variable below with the value of `gcp-environments` repository path.

    ```bash
    export GCP_ENVIRONMENTS_PATH=INSERT_YOUR_PATH_HERE
    ```

    Make sure your git is checked out to the `non-production` branch by running `git checkout nonproduction` on `GCP_ENVIRONMENTS_PATH`.

    ```bash
    (cd $GCP_ENVIRONMENTS_PATH && git checkout nonproduction)
    ```

2. Retrieve the bucket name and project id from terraform outputs.

    ```bash
    export ENV_LOG_BUCKET_NAME=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/nonproduction" output -raw env_log_bucket_name)
    export ENV_LOG_PROJECT_ID=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/nonproduction" output -raw env_log_project_id)
    ```

3. Validate the variable values.

    ```bash
    echo env_log_project_id=$ENV_LOG_PROJECT_ID
    echo env_log_bucket_name=$ENV_LOG_BUCKET_NAME
    ```

4. Reset your org policy for the logging project by running the following command.

    ```bash
    gcloud org-policies reset iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

5. Assign `roles/storage.objectCreator` role to `cloud-storage-analytics@google.com` group.

    ```bash
    gcloud storage buckets add-iam-policy-binding gs://$ENV_LOG_BUCKET_NAME --member="group:cloud-storage-analytics@google.com" --role="roles/storage.objectCreator"
    ```

    > Note: you might receive an error telling you that this is against an organization policy, this can happen because of the propagation time from the change made to the organization policy (propagation time is tipically 2 minutes, but can take 7 minutes or longer). If this happens, wait some minutes and try again

6. Delete the change made on the first step to the organization policy, this will make the project inherit parent policies.

    ```bash
    gcloud org-policies delete iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

##### `production` environment configuration

1. Configure the following variable below with the value of `gcp-environments` repository path.

    ```bash
    export GCP_ENVIRONMENTS_PATH=INSERT_YOUR_PATH_HERE
    ```

    Make sure your git is checked out to the `production` branch by running `git checkout production` on `GCP_ENVIRONMENTS_PATH`.

    ```bash
    (cd $GCP_ENVIRONMENTS_PATH && git checkout production)
    ```

2. Retrieve the bucket name and project id from terraform outputs.

    ```bash
    export ENV_LOG_BUCKET_NAME=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/production" output -raw env_log_bucket_name)
    export ENV_LOG_PROJECT_ID=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/production" output -raw env_log_project_id)
    ```

3. Validate the variable values.

    ```bash
    echo env_log_project_id=$ENV_LOG_PROJECT_ID
    echo env_log_bucket_name=$ENV_LOG_BUCKET_NAME
    ```

4. Reset your org policy for the logging project by running the following command.

    ```bash
    gcloud org-policies reset iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

5. Assign `roles/storage.objectCreator` role to `cloud-storage-analytics@google.com` group.

    ```bash
    gcloud storage buckets add-iam-policy-binding gs://$ENV_LOG_BUCKET_NAME --member="group:cloud-storage-analytics@google.com" --role="roles/storage.objectCreator"
    ```

    > Note: you might receive an error telling you that this is against an organization policy, this can happen because of the propagation time from the change made to the organization policy (propagation time is tipically 2 minutes, but can take 7 minutes or longer). If this happens, wait some minutes and try again

6. Delete the change made on the first step to the organization policy, this will make the project inherit parent policies.

    ```bash
    gcloud org-policies delete iam.allowedPolicyMemberDomains --project=$ENV_LOG_PROJECT_ID
    ```

#### Option 2: Use Google Cloud Console to disable/enable organization policy constraint

Proceed with these steps only if `Option 1` is not chosen.

1. On `ml_logging.tf` locate the following lines and uncomment them:

    ```terraform
    resource "google_storage_bucket_iam_member" "bucket_logging" {
      bucket = google_storage_bucket.log_bucket.name
      role   = "roles/storage.objectCreator"
      member = "group:cloud-storage-analytics@google.com"
    }
    ```

2. Under `IAM & Admin`, select `Organization Policies`.  Search for "Domain Restricted Sharing".

    ![list-policy](../2-environments/imgs/list-policy.png)

3. Select 'Manage Policy'.  This directs you to the Domain Restricted Sharing Edit Policy page.  It will be set at 'Inherit parent's policy'.  Change this to 'Google-managed default'.

    ![edit-policy](../2-environments/imgs/edit-policy.png)

4. Follow the instructions on checking out `development`, `non-production` & `production` branches. Once environments terraform code has successfully applied, edit the policy again and select 'Inherit parent's policy' and Click `SET POLICY`.

After making these modifications, you can follow the README.md procedure for `2-environment` step on foundation, make sure you **change the organization policy after running the steps on foundation**.

## 3-network: Configure private DNS zone for Vertex Workbench Instances, Enable NAT and Attach projects to perimeter

This step corresponds to modifications made to `3-networks-dual-svpc` step on foundation.

Please note that the steps below are assuming you are checked out on `terraform-google-enterprise-genai/`.

```bash
cd ../terraform-google-enterprise-genai
```

### `development` branch on `gcp-networks`

- Go to `gcp-networks` repository, and check out on `development` branch.

```bash
cd ../gcp-networks

git checkout development
```

#### Private DNS zone configuration (dev)

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy DNS notebook network module from this repo to `gcp-networks` repository.

```bash
cp -r 3-networks-dual-svpc/modules/ml_dns_notebooks ../gcp-networks/modules
```

- Create a file named `ml_dns_notebooks.tf` on path `gcp-networks/modules/base_env`:

```bash
cp docs/assets/terraform/3-networks-dual-svpc/ml_dns_notebooks.tf ../gcp-networks/modules/base_env
```

Commit and push files to git repo.

```bash
cd ../gcp-networks

git add .

git commit -m "Create DNS notebook configuration"

git push origin development
```

#### Enabling NAT, Attaching projects to Service Perimeter and Creating custom firewall rules (dev)

Create `gcp-networks/modules/base_env/data.tf` file with the following content:

```terraform
/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

// Cloud IAP's TCP forwarding netblock
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}
```

On `gcp-networks/modules/restricted_shared_vpc/variables.tf` add the following variables:

```terraform
variable "perimeter_projects" {
  description = "A list of project numbers to be added to the service perimeter"
  type        = list(number)
  default     = []
}

variable "allow_all_egress_ranges" {
  description = "List of network ranges to which all egress traffic will be allowed"
  default     = null
}

variable "allow_all_ingress_ranges" {
  description = "List of network ranges from which all ingress traffic will be allowed"
  default     = null
}
```

On `gcp-networks/modules/base_env/remote.tf`:

1. Add the env remote state, by adding the following terraform code to the file:

    ```terraform
    data "terraform_remote_state" "env" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/environments/${var.env}"
      }
    }
    ```

2. Edit `locals` and add the following fields:

    ```terraform
    logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
    kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    ```

3. The final result will contain existing locals and the added ones, it should look similar to the code below:

    ```terraform
    locals {
      restricted_project_id        = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_id
      restricted_project_number    = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_number
      base_project_id              = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].base_shared_vpc_project_id
      interconnect_project_number  = data.terraform_remote_state.org.outputs.interconnect_project_number
      dns_hub_project_id           = data.terraform_remote_state.org.outputs.dns_hub_project_id
      organization_service_account = data.terraform_remote_state.bootstrap.outputs.organization_step_terraform_service_account_email
      networks_service_account     = data.terraform_remote_state.bootstrap.outputs.networks_step_terraform_service_account_email
      projects_service_account     = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
      logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
      kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    }
    ```

##### Adding projects to service perimeter (dev)

On `gcp-networks/modules/restricted_shared_vpc/service_control.tf`, modify the terraform module called **regular_service_perimeter** and add the following module field to `resources`:

```terraform
distinct(concat([var.project_number], var.perimeter_projects))
```

This shall result in a module similar to the code below:

```terraform
module "regular_service_perimeter" {
  source  = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  version = "~> 4.0"

  policy         = var.access_context_manager_policy_id
  perimeter_name = local.perimeter_name
  description    = "Default VPC Service Controls perimeter"
  resources      = distinct(concat([var.project_number], var.perimeter_projects))
  access_levels  = [module.access_level_members.name]

  restricted_services     = var.restricted_services
  vpc_accessible_services = ["RESTRICTED-SERVICES"]

  ingress_policies = var.ingress_policies
  egress_policies  = var.egress_policies

  depends_on = [
    time_sleep.wait_vpc_sc_propagation
  ]
}
```

##### Creating "allow all ingress ranges" and "allow all egress ranges" firewall rules (dev)

On `gcp-networks/modules/restricted_shared_vpc/firewall.tf` add the following firewall rules by adding the terraform code below to the file:

```terraform
resource "google_compute_firewall" "allow_all_egress" {
  count = var.allow_all_egress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-e-a-all-all-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "EGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  destination_ranges = var.allow_all_egress_ranges
}

resource "google_compute_firewall" "allow_all_ingress" {
  count = var.allow_all_ingress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-i-a-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "INGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  source_ranges = var.allow_all_ingress_ranges
}
```

##### Changes to restricted shared VPC (dev)

On `gcp-networks/modules/base_env/main.tf` edit the terraform module named **restricted_shared_vpc** and add the following fields to it:

```terraform
allow_all_ingress_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
allow_all_egress_ranges  = ["0.0.0.0/0"]

nat_enabled               = true
nat_num_addresses_region1 = 1
nat_num_addresses_region2 = 1

perimeter_projects = [local.logging_env_project_number, local.kms_env_project_number]
```

Commit all changes and push to the current branch.

```bash
git add .
git commit -m "Create custom fw rules, enable nat, configure dns and service perimeter"

git push origin development
```

### `nonproduction` branch on `gcp-networks`

- Go to `gcp-networks` repository, and check out on `nonproduction` branch.

```bash
cd ../gcp-networks

git checkout nonproduction
```

#### Private DNS zone configuration (non-production)

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy DNS notebook network module from this repo to `gcp-networks` repository.

```bash
cp -r 3-networks-dual-svpc/modules/ml_dns_notebooks ../gcp-networks/modules
```

- Create a file named `ml_dns_notebooks.tf` on path `gcp-networks/modules/base_env`:

```bash
cp docs/assets/terraform/3-networks-dual-svpc/ml_dns_notebooks.tf ../gcp-networks/modules/base_env
```

Commit and push files to git repo.

```bash
cd ../gcp-networks

git add .

git commit -m "Create DNS notebook configuration"

git push origin nonproduction
```

#### Enabling NAT, Attaching projects to Service Perimeter and Creating custom firewall rules (non-production)

Create `gcp-networks/modules/base_env/data.tf` file with the following content:

```terraform
/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

// Cloud IAP's TCP forwarding netblock
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}
```

On `gcp-networks/modules/restricted_shared_vpc/variables.tf` add the following variables:

```terraform
variable "perimeter_projects" {
  description = "A list of project numbers to be added to the service perimeter"
  type        = list(number)
  default     = []
}

variable "allow_all_egress_ranges" {
  description = "List of network ranges to which all egress traffic will be allowed"
  default     = null
}

variable "allow_all_ingress_ranges" {
  description = "List of network ranges from which all ingress traffic will be allowed"
  default     = null
}
```

On `gcp-networks/modules/base_env/remote.tf`:

1. Add the env remote state, by adding the following terraform code to the file:

    ```terraform
    data "terraform_remote_state" "env" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/environments/${var.env}"
      }
    }
    ```

2. Edit `locals` and add the following fields:

    ```terraform
    logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
    kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    ```

3. The final result will contain existing locals and the added ones, it should look similar to the code below:

    ```terraform
    locals {
      restricted_project_id        = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_id
      restricted_project_number    = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_number
      base_project_id              = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].base_shared_vpc_project_id
      interconnect_project_number  = data.terraform_remote_state.org.outputs.interconnect_project_number
      dns_hub_project_id           = data.terraform_remote_state.org.outputs.dns_hub_project_id
      organization_service_account = data.terraform_remote_state.bootstrap.outputs.organization_step_terraform_service_account_email
      networks_service_account     = data.terraform_remote_state.bootstrap.outputs.networks_step_terraform_service_account_email
      projects_service_account     = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
      logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
      kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    }
    ```

##### Adding projects to service perimeter (non-production)

On `gcp-networks/modules/restricted_shared_vpc/service_control.tf`, modify the terraform module called **regular_service_perimeter** and add the following module field to `resources`:

```terraform
distinct(concat([var.project_number], var.perimeter_projects))
```

This shall result in a module similar to the code below:

```terraform
module "regular_service_perimeter" {
  source  = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  version = "~> 4.0"

  policy         = var.access_context_manager_policy_id
  perimeter_name = local.perimeter_name
  description    = "Default VPC Service Controls perimeter"
  resources      = distinct(concat([var.project_number], var.perimeter_projects))
  access_levels  = [module.access_level_members.name]

  restricted_services     = var.restricted_services
  vpc_accessible_services = ["RESTRICTED-SERVICES"]

  ingress_policies = var.ingress_policies
  egress_policies  = var.egress_policies

  depends_on = [
    time_sleep.wait_vpc_sc_propagation
  ]
}
```

##### Creating "allow all ingress ranges" and "allow all egress ranges" firewall rules (non-production)

On `gcp-networks/modules/restricted_shared_vpc/firewall.tf` add the following firewall rules by adding the terraform code below to the file:

```terraform
resource "google_compute_firewall" "allow_all_egress" {
  count = var.allow_all_egress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-e-a-all-all-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "EGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  destination_ranges = var.allow_all_egress_ranges
}

resource "google_compute_firewall" "allow_all_ingress" {
  count = var.allow_all_ingress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-i-a-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "INGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  source_ranges = var.allow_all_ingress_ranges
}
```

##### Changes to restricted shared VPC (non-production)

On `gcp-networks/modules/base_env/main.tf` edit the terraform module named **restricted_shared_vpc** and add the following fields to it:

```terraform
allow_all_ingress_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
allow_all_egress_ranges  = ["0.0.0.0/0"]

nat_enabled               = true
nat_num_addresses_region1 = 1
nat_num_addresses_region2 = 1

perimeter_projects = [local.logging_env_project_number, local.kms_env_project_number]
```

Commit all changes and push to the current branch.

```bash
git add .
git commit -m "Create custom fw rules, enable nat, configure dns and service perimeter"

git push origin nonproduction
```

### `production` branch on `gcp-networks`

- Go to `gcp-networks` repository, and check out on `production` branch.

```bash
cd ../gcp-networks

git checkout production
```

#### Private DNS zone configuration (production)

- Return to `terraform-google-enterprise-genai` repo.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy DNS notebook network module from this repo to `gcp-networks` repository.

```bash
cp -r 3-networks-dual-svpc/modules/ml_dns_notebooks ../gcp-networks/modules
```

- Create a file named `ml_dns_notebooks.tf` on path `gcp-networks/modules/base_env`:

```bash
cp docs/assets/terraform/3-networks-dual-svpc/ml_dns_notebooks.tf ../gcp-networks/modules/base_env
```

Commit and push files to git repo.

```bash
cd ../gcp-networks

git add .

git commit -m "Create DNS notebook configuration"

git push origin production
```

#### Enabling NAT, Attaching projects to Service Perimeter and Creating custom firewall rules (production)

Create `gcp-networks/modules/base_env/data.tf` file with the following content:

```terraform
/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

// Cloud IAP's TCP forwarding netblock
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}
```

On `gcp-networks/modules/restricted_shared_vpc/variables.tf` add the following variables:

```terraform
variable "perimeter_projects" {
  description = "A list of project numbers to be added to the service perimeter"
  type        = list(number)
  default     = []
}

variable "allow_all_egress_ranges" {
  description = "List of network ranges to which all egress traffic will be allowed"
  default     = null
}

variable "allow_all_ingress_ranges" {
  description = "List of network ranges from which all ingress traffic will be allowed"
  default     = null
}
```

On `gcp-networks/modules/base_env/remote.tf`:

1. Add the env remote state, by adding the following terraform code to the file:

    ```terraform
    data "terraform_remote_state" "env" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/environments/${var.env}"
      }
    }
    ```

2. Edit `locals` and add the following fields:

    ```terraform
    logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
    kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    ```

3. The final result will contain existing locals and the added ones, it should look similar to the code below:

    ```terraform
    locals {
      restricted_project_id        = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_id
      restricted_project_number    = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].restricted_shared_vpc_project_number
      base_project_id              = data.terraform_remote_state.org.outputs.shared_vpc_projects[var.env].base_shared_vpc_project_id
      interconnect_project_number  = data.terraform_remote_state.org.outputs.interconnect_project_number
      dns_hub_project_id           = data.terraform_remote_state.org.outputs.dns_hub_project_id
      organization_service_account = data.terraform_remote_state.bootstrap.outputs.organization_step_terraform_service_account_email
      networks_service_account     = data.terraform_remote_state.bootstrap.outputs.networks_step_terraform_service_account_email
      projects_service_account     = data.terraform_remote_state.bootstrap.outputs.projects_step_terraform_service_account_email
      logging_env_project_number   = data.terraform_remote_state.env.outputs.env_log_project_number
      kms_env_project_number       = data.terraform_remote_state.env.outputs.env_kms_project_number
    }
    ```

##### Adding projects to service perimeter (production)

On `gcp-networks/modules/restricted_shared_vpc/service_control.tf`, modify the terraform module called **regular_service_perimeter** and add the following module field to `resources`:

```terraform
distinct(concat([var.project_number], var.perimeter_projects))
```

This shall result in a module similar to the code below:

```terraform
module "regular_service_perimeter" {
  source  = "terraform-google-modules/vpc-service-controls/google//modules/regular_service_perimeter"
  version = "~> 4.0"

  policy         = var.access_context_manager_policy_id
  perimeter_name = local.perimeter_name
  description    = "Default VPC Service Controls perimeter"
  resources      = distinct(concat([var.project_number], var.perimeter_projects))
  access_levels  = [module.access_level_members.name]

  restricted_services     = var.restricted_services
  vpc_accessible_services = ["RESTRICTED-SERVICES"]

  ingress_policies = var.ingress_policies
  egress_policies  = var.egress_policies

  depends_on = [
    time_sleep.wait_vpc_sc_propagation
  ]
}
```

##### Creating "allow all ingress ranges" and "allow all egress ranges" firewall rules (production)

On `gcp-networks/modules/restricted_shared_vpc/firewall.tf` add the following firewall rules by adding the terraform code below to the file:

```terraform
resource "google_compute_firewall" "allow_all_egress" {
  count = var.allow_all_egress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-e-a-all-all-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "EGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  destination_ranges = var.allow_all_egress_ranges
}

resource "google_compute_firewall" "allow_all_ingress" {
  count = var.allow_all_ingress_ranges != null ? 1 : 0

  name      = "fw-${var.environment_code}-shared-base-1000-i-a-all"
  network   = module.main.network_name
  project   = var.project_id
  direction = "INGRESS"
  priority  = 1000

  dynamic "log_config" {
    for_each = var.firewall_enable_logging == true ? [{
      metadata = "INCLUDE_ALL_METADATA"
    }] : []

    content {
      metadata = log_config.value.metadata
    }
  }

  allow {
    protocol = "all"
  }

  source_ranges = var.allow_all_ingress_ranges
}
```

##### Changes to restricted shared VPC (production)

On `gcp-networks/modules/base_env/main.tf` edit the terraform module named **restricted_shared_vpc** and add the following fields to it:

```terraform
allow_all_ingress_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
allow_all_egress_ranges  = ["0.0.0.0/0"]

nat_enabled               = true
nat_num_addresses_region1 = 1
nat_num_addresses_region2 = 1

perimeter_projects = [local.logging_env_project_number, local.kms_env_project_number]
```

Commit all changes and push to the current branch.

```bash
git add .
git commit -m "Create custom fw rules, enable nat, configure dns and service perimeter"

git push origin production
```

## 4-projects: Create Service Catalog and Artifacts Shared projects and Machine Learning Projects

This step corresponds to modifications made to `4-projects` step on foundation.

Please note that the steps below are assuming you are checked out on `terraform-google-enterprise-genai/`.

```bash
cd ../terraform-google-enterprise-genai
```

In this tutorial, we are using `ml_business_unit` as an example.

You need to manually plan and apply only once the `ml_business_unit/shared`.

### Manually applying `shared`

- Go to `gcp-projects` repository and checkout to `plan` branch.

```bash
cd ../gcp-projects

git checkout plan
```

- Return to GenAI repository.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy `ml_business_unit` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/ml_business_unit ../gcp-projects
```

- Add modules to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/modules/* ../gcp-projects/modules
```

- Add `tfvars` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/*.example.tfvars ../gcp-projects
```

- Go to `gcp-projects` repository.

```bash
cd ../gcp-projects
```

- Update project backend by retrieving it's value from `0-bootstrap` and applying it to `backend.tf`.

```bash
export PROJECT_BACKEND=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)

for file in $(find . -name backend.tf); do sed -i "s/UPDATE_PROJECTS_BACKEND/$PROJECT_BACKEND/" $file; done
```

- Retrieve projects step service account e-mail.

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_step_terraform_service_account_email)
echo ${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
```

- Retrieve cloud build project id.

```bash
export CLOUD_BUILD_PROJECT_ID=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw cloudbuild_project_id)
echo ${CLOUD_BUILD_PROJECT_ID}
```

- Rename `auto.example.tfvars` to `auto.tfvars`.

```bash
mv common.auto.example.tfvars common.auto.tfvars
mv shared.auto.example.tfvars shared.auto.tfvars
mv development.auto.example.tfvars development.auto.tfvars
mv non-production.auto.example.tfvars non-production.auto.tfvars
mv production.auto.example.tfvars production.auto.tfvars
```

- Update REMOTE_STATE_BUCKET value.

```bash
export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)
echo "remote_state_bucket = ${remote_state_bucket}"

sed -i'' -e "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
```

- Commit the changes.

```bash
git add .

git commit -m "Create ML Business Unit"
```

- Log into gcloud using service account impersonation and then set your configuration:

```bash
gcloud auth application-default login --impersonate-service-account=${GOOGLE_IMPERSONATE_SERVICE_ACCOUNT}
```

- Run `init` and `plan` and review output for environment shared.

```bash
./tf-wrapper.sh init shared
./tf-wrapper.sh plan shared
```

- Run `validate` and check for violations.

```bash
./tf-wrapper.sh validate shared $(pwd)/../gcp-policies ${CLOUD_BUILD_PROJECT_ID}
```

- Run `apply` shared.

```bash
./tf-wrapper.sh apply shared
```

This will create the artifacts and service catalog projects under `common` folder and configure the Machine Learning business unit infra pipeline.

Push plan branch to remote.

```bash
git push origin plan
```

### `development` branch on `gcp-projects`

This will create the machine learning development environment. A Machine Learning project will be hosted under a folder.

- Go to `gcp-projects` repository and checkout to `plan` branch.

```bash
cd ../gcp-projects

git checkout development
```

- Return to GenAI repository.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy `ml_business_unit` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/ml_business_unit ../gcp-projects
```

- Add modules to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/modules/* ../gcp-projects/modules
```

- Add `tfvars` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/*.example.tfvars ../gcp-projects
```

- Go to `gcp-projects` repository.

```bash
cd ../gcp-projects
```

- Rename `auto.example.tfvars` to `auto.tfvars`.

```bash
mv common.auto.example.tfvars common.auto.tfvars
mv shared.auto.example.tfvars shared.auto.tfvars
mv development.auto.example.tfvars development.auto.tfvars
mv non-production.auto.example.tfvars non-production.auto.tfvars
mv production.auto.example.tfvars production.auto.tfvars
```

- Update REMOTE_STATE_BUCKET value.

```bash
export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)
echo "remote_state_bucket = ${remote_state_bucket}"

sed -i'' -e "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
```

- Update project backend by retrieving it's value from `0-bootstrap` and applying it to `backend.tf`.

```bash
export PROJECT_BACKEND=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)

for file in $(find . -name backend.tf); do sed -i "s/UPDATE_PROJECTS_BACKEND/$PROJECT_BACKEND/" $file; done
```

- Commit and push.

```bash
git add .
git commit -m "Initialize ML environment"

git push origin development
```

### `nonproduction` branch on `gcp-projects`

This will create the machine learning nonproduction environment. A Machine Learning project will be hosted under a folder.

- Go to `gcp-projects` repository and checkout to `plan` branch.

```bash
cd ../gcp-projects

git checkout nonproduction
```

- Return to GenAI repository.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy `ml_business_unit` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/ml_business_unit ../gcp-projects
```

- Add modules to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/modules/* ../gcp-projects/modules
```

- Add `tfvars` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/*.example.tfvars ../gcp-projects
```

- Go to `gcp-projects` repository.

```bash
cd ../gcp-projects
```

- Rename `auto.example.tfvars` to `auto.tfvars`.

```bash
mv common.auto.example.tfvars common.auto.tfvars
mv shared.auto.example.tfvars shared.auto.tfvars
mv development.auto.example.tfvars development.auto.tfvars
mv non-production.auto.example.tfvars non-production.auto.tfvars
mv production.auto.example.tfvars production.auto.tfvars
```

- Update REMOTE_STATE_BUCKET value.

```bash
export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)
echo "remote_state_bucket = ${remote_state_bucket}"

sed -i'' -e "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
```

- Update project backend by retrieving it's value from `0-bootstrap` and applying it to `backend.tf`.

```bash
export PROJECT_BACKEND=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)

for file in $(find . -name backend.tf); do sed -i "s/UPDATE_PROJECTS_BACKEND/$PROJECT_BACKEND/" $file; done
```

- Commit and push.

```bash
git add .
git commit -m "Initialize ML environment"

git push origin nonproduction
```

### `production` branch on `gcp-projects`

This will create the machine learning production environment. A Machine Learning project will be hosted under a folder.

- Go to `gcp-projects` repository and checkout to `plan` branch.

```bash
cd ../gcp-projects

git checkout production
```

- Return to GenAI repository.

```bash
cd ../terraform-google-enterprise-genai
```

- Copy `ml_business_unit` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/ml_business_unit ../gcp-projects
```

- Remove shared directory on `ml_business_unit` on the `gcp-projects` repository.

```bash
rm -rf ../gcp-projects/ml_business_unit/shared
```

- Add modules to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/modules/* ../gcp-projects/modules
```

- Add `tfvars` to the `gcp-projects` repository.

```bash
cp -r docs/assets/terraform/4-projects/*.example.tfvars ../gcp-projects
```

- Go to `gcp-projects` repository.

```bash
cd ../gcp-projects
```

- Rename `auto.example.tfvars` to `auto.tfvars`.

```bash
mv common.auto.example.tfvars common.auto.tfvars
mv shared.auto.example.tfvars shared.auto.tfvars
mv development.auto.example.tfvars development.auto.tfvars
mv non-production.auto.example.tfvars non-production.auto.tfvars
mv production.auto.example.tfvars production.auto.tfvars
```

- Update REMOTE_STATE_BUCKET value.

```bash
export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw gcs_bucket_tfstate)
echo "remote_state_bucket = ${remote_state_bucket}"

sed -i'' -e "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
```

- Update project backend by retrieving it's value from `0-bootstrap` and applying it to `backend.tf`.

```bash
export PROJECT_BACKEND=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)

for file in $(find . -name backend.tf); do sed -i "s/UPDATE_PROJECTS_BACKEND/$PROJECT_BACKEND/" $file; done
```

- Commit and push.

```bash
git add .
git commit -m "Initialize ML environment"

git push origin production
```

## 5-appinfra: Deploy Service Catalog and Artifacts Publish Applications

### Update `gcloud terraform vet` policies for app-infra

The first step is to update the `gcloud terraform vet` policies constraints to allow usage of the APIs needed by the Blueprint and add more policies.

The constraints are located in the repository:

- `gcp-policies-app-infra`

**IMPORTANT:** Please note that the steps below are assuming you are checked out on the same level as `terraform-google-enterprise-genai/` and the other repos (`gcp-bootstrap`, `gcp-org`, `gcp-projects`...).

- Clone the `gcp-policies-app-infra` repo based on the Terraform output from the `4-projects` step.
Clone the repo at the same level of the `terraform-google-enterprise-genai` folder, the following instructions assume this layout.
Run `terraform output cloudbuild_project_id` in the `4-projects` folder to get the Cloud Build Project ID.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   gcloud source repos clone gcp-policies gcp-policies-app-infra --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

   **Note:** `gcp-policies` repo has the same name as the repo created in step `1-org`. In order to prevent a collision, the previous command will clone this repo in the folder `gcp-policies-app-infra`.

- Navigate into the repo and copy contents of policy-library to new repo. All subsequent steps assume you are running them from the gcp-policies-app-infra directory. If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd gcp-policies-app-infra/
   git checkout -b main

   cp -RT ../terraform-google-enterprise-genai/policy-library/ .
   ```

- Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Initialize policy library repo'

   git push --set-upstream origin main
   ```

- Navigate out of the repo.

   ```bash
   cd ..
   ```

### Artifacts Application

The purpose of this step is to deploy out an artifact registry to store custom docker images. A Cloud Build pipeline is also deployed out. At the time of this writing, it is configured to attach itself to a Cloud Source Repository. The Cloud Build pipeline is responsible for building out a custom image that may be used in Machine Learning Workflows.  If you are in a situation where company policy requires no outside repositories to be accessed, custom images can be used to keep access to any image internally.

Since every workflow will have access to these images, it is deployed in the `common` folder, and keeping with the foundations structure, is listed as `shared` under this Business Unit.  It will only need to be deployed once.

The Pipeline is connected to a Google Cloud Source Repository with a simple structure:

   ```txt
   ├── README.md
   └── images
      ├── tf2-cpu.2-13:0.1
      │   └── Dockerfile
      └── tf2-gpu.2-13:0.1
         └── Dockerfile
   ```

For the purposes of this example, the pipeline is configured to monitor the `main` branch of this repository.

Each folder under `images` has the full name and tag of the image that must be built.  Once a change to the `main` branch is pushed, the pipeline will analyse which files have changed and build that image out and place it in the artifact repository.  For example, if there is a change to the Dockerfile in the `tf2-cpu-13:0.1` folder, or if the folder itself has been renamed, it will build out an image and tag it based on the folder name that the Dockerfile has been housed in.

Once pushed, the pipeline build logs can be accessed by navigating to the artifacts project name created in step-4:

   ```bash
   terraform -chdir="gcp-projects/ml_business_unit/shared/" output -raw common_artifacts_project_id
   ```

- Clone the `ml-artifact-publish` repo.

   ```bash
   gcloud source repos clone ml-artifact-publish --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

- Navigate into the repo, change to non-main branch and copy contents of GenAI to the new repo. Subsequent steps assume you are running them from the `ml-artifact-publish` directory.

   ```bash
   cd ml-artifact-publish/
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/artifact-publish/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

- Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

- Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./business_unit_1/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

- Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-artifact-publish"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

- Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize repo'
   ```

- Push your plan branch to trigger a plan for all environments. Because the _plan_ branch is not a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing your _plan_ branch triggers _terraform plan_ but not _terraform apply_. Review the plan output in your Cloud Build project `https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID`.

   ```bash
   git push --set-upstream origin plan
   ```

- Merge changes to shared. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project `https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID`. Before proceeding further, make sure that the build applied successfully.

   ```bash
   git checkout -b production
   git push origin production
   ```

- `cd` out of the `ml-artifacts-publish` repository.

   ```bash
   cd ..
   ```

#### Configuring Cloud Source Repository of Artifact Application

The series of steps below will trigger the custom artifacts pipeline.

- Grab the Artifact Project ID

   ```bash
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared" output -raw common_artifacts_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

- Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```

- Enter the repo folder and copy over the example files from the folder on GenAI repository.

   ```bash
   cd publish-artifacts
   git checkout -b main

   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/artifact-publish/ .
   ```

- Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Build Images'

   git push --set-upstream origin main
   ```

- `cd` out of the `publish-artifacts` repository.

   ```bash
   cd ..
   ```

### Service Catalog Pipeline Configuration

This step has two main purposes:

1. To deploy a pipeline and a bucket which is linked to a Google Cloud Repository that houses terraform modules for the use in Service Catalog.
Although Service Catalog itself must be manually deployed, the modules which will be used can still be automated.

2. To deploy infrastructure for operational environments (ie. `non-production` & `production`.)

The resoning behind utilizing one repository with two deployment methodologies is due to how close interactive (`development`) and operational environments are.

The repository has the structure (truncated for brevity):

   ```text
   ml_business_unit
   ├── development
   ├── non-production
   ├── production
   modules
   ├── bucket
   │   ├── README.md
   │   ├── data.tf
   │   ├── main.tf
   │   ├── outputs.tf
   │   ├── provider.tf
   │   └── variables.tf
   ├── composer
   │   ├── README.md
   │   ├── data.tf
   │   ├── iam.roles.tf
   │   ├── iam.users.tf
   │   ├── locals.tf
   │   ├── main.tf
   │   ├── outputs.tf
   │   ├── provider.tf
   │   ├── terraform.tfvars.example
   │   ├── variables.tf
   │   └── vpc.tf
   ├── cryptography
   │   ├── README.md
   │   ├── crypto_key
   │   │   ├── main.tf
   │   │   ├── outputs.tf
   │   │   └── variables.tf
   │   └── key_ring
   │       ├── main.tf
   │       ├── outputs.tf
   │       └── variables.tf
   ```

Each folder under `modules` represents a terraform module.
When there is a change in any of the terraform module folders, the pipeline will find whichever module has been changed since the last push, `tar.gz` that file and place it in a bucket for Service Catalog to access.

This pipeline is listening to the `main` branch of this repository for changes in order for the modules to be uploaded to service catalog.

The pipeline also listens for changes made to `plan`, `development`, `non-production` & `production` branches, this is used for deploying infrastructure to each project.

- Clone the `ml-service-catalog` repo.

   ```bash
   gcloud source repos clone ml-service-catalog --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

- Navigate into the repo, change to non-main branch and copy contents of foundation to new repo. All subsequent steps assume you are running them from the ml-service-catalog directory. If you run them from another directory, adjust your copy paths accordingly.

   ```bash
   cd ml-service-catalog
   git checkout -b plan

   cp -RT ../terraform-google-enterprise-genai/5-app-infra/projects/service-catalog/ .
   cp -R ../terraform-google-enterprise-genai/5-app-infra/modules/ ./modules
   cp ../terraform-google-enterprise-genai/build/cloudbuild-tf-* .
   cp ../terraform-google-enterprise-genai/build/tf-wrapper.sh .
   chmod 755 ./tf-wrapper.sh
   ```

- Rename `common.auto.example.tfvars` to `common.auto.tfvars`.

   ```bash
   mv common.auto.example.tfvars common.auto.tfvars
   ```

- Update the file with values from your environment and 0-bootstrap. See any of the business unit 1 envs folders [README.md](./business_unit_1/production/README.md) files for additional information on the values in the `common.auto.tfvars` file.

   ```bash
   export remote_state_bucket=$(terraform -chdir="../gcp-bootstrap/envs/shared" output -raw projects_gcs_bucket_tfstate)
   echo "remote_state_bucket = ${remote_state_bucket}"
   sed -i "s/REMOTE_STATE_BUCKET/${remote_state_bucket}/" ./common.auto.tfvars
   ```

- Update the `log_bucket` variable with the value of the `logs_export_storage_bucket_name`.

  ```bash
   export log_bucket=$(terraform -chdir="../gcp-org/envs/shared" output -raw logs_export_storage_bucket_name)
   echo "log_bucket = ${log_bucket}"
   sed -i "s/REPLACE_LOG_BUCKET/${log_bucket}/" ./common.auto.tfvars
   ```

- Update `backend.tf` with your bucket from the infra pipeline output.

   ```bash
   export backend_bucket=$(terraform -chdir="../gcp-projects/ml_business_unit/shared/" output -json state_buckets | jq '."ml-service-catalog"' --raw-output)
   echo "backend_bucket = ${backend_bucket}"

   for i in `find -name 'backend.tf'`; do sed -i "s/UPDATE_APP_INFRA_BUCKET/${backend_bucket}/" $i; done
   ```

- Commit changes.

   ```bash
   git add .
   git commit -m 'Initialize repo'
   ```

- Push your plan branch to trigger a plan for all environments. Because the _plan_ branch is not a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing your _plan_ branch triggers _terraform plan_ but not _terraform apply_. Review the plan output in your Cloud Build project `https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID`.

   ```bash
   git push --set-upstream origin plan
   ```

- Merge changes to production. Because this is a [named environment branch](../docs/FAQ.md#what-is-a-named-branch), pushing to this branch triggers both _terraform plan_ and _terraform apply_. Review the apply output in your Cloud Build project `https://console.cloud.google.com/cloud-build/builds;region=DEFAULT_REGION?project=YOUR_INFRA_PIPELINE_PROJECT_ID`. Before proceeding further, make sure that the build applied successfully.

   ```bash
   git checkout -b production
   git push origin production
   ```

- `cd` out of the `ml-service-catalog` repository.

   ```bash
   cd ..
   ```

#### Configuring Cloud Source Repository of Service Catalog Solutions Pipeline

The series of steps below will trigger the custom Service Catalog Pipeline.

- Grab the Service Catalogs ID

   ```bash
   export SERVICE_CATALOG_PROJECT_ID=$(terraform -chdir="gcp-projects/ml_business_unit/shared" output -raw service_catalog_project_id)
   echo ${SERVICE_CATALOG_PROJECT_ID}
   ```

- Clone the freshly minted Cloud Source Repository that was created for this project.

   ```bash
   gcloud source repos clone service-catalog --project=${SERVICE_CATALOG_PROJECT_ID}
   ```

- Enter the repo folder and copy over the service catalogs files from `5-app-infra/source_repos/service-catalog` folder.

   ```bash
   cd service-catalog/
   cp -RT ../terraform-google-enterprise-genai/5-app-infra/source_repos/service-catalog/ .
   git add img
   git commit -m "Add img directory"
   ```

- Commit changes and push main branch to the new repo.

   ```bash
   git add modules
   git commit -m 'Initialize Service Catalog Build Repo'

   git push --set-upstream origin main
   ```

- `cd` out of the `service_catalog` repository.

   ```bash
   cd ..
   ```

- Navigate to the project that was output from `${SERVICE_CATALOG_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.
