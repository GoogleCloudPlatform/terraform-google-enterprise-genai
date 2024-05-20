# Deploying on top of existing Foundation v.4.0.0

# Overview

To deploy a simple machine learning application, you must first have a [terraform-example-foundation v4.0.0](https://github.com/terraform-google-modules/terraform-example-foundation/tree/v4.0.0) instance set up. The following steps will guide you through the additional configurations required on top of the foundation.

# 1-org: Create Machine Learning Organization Policies and Organization Level Keys

This step corresponds to modifications made to `1-org` step on foundation.

- Create `ml_ops_org_policy.tf` file on `1-org/envs/shared` path, with the following content:

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

module "ml_organization_policies" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//1-org/modules/ml-org-policies?ref=fe3b1b453906d781d22743782afc92664d517b69"

  org_id    = local.organization_id
  folder_id = local.folder_id

  allowed_locations = [
    "in:us-locations"
  ]

  allowed_vertex_vpc_networks = {
    parent_type = "project"
    ids         = [for instance in module.base_restricted_environment_network : instance.restricted_shared_vpc_project_id],
  }

  allowed_vertex_images = [
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cpu-notebooks",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py37",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu110.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-cpu.2-12.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-gpu.2-12.py310"
  ]

  restricted_services = [
    "alloydb.googleapis.com"
  ]

  allowed_integrations = [
    "github.com",
    "source.developers.google.com"
  ]

  restricted_tls_versions = [
    "TLS_VERSION_1",
    "TLS_VERSION_1_1"
  ]

  restricted_non_cmek_services = [
    "bigquery.googleapis.com",
    "aiplatform.googleapis.com"
  ]

  allowed_vertex_access_modes = [
    "single-user",
    "service-account"
  ]
}
```
- Create `ml_key_rings.tf` file on `1-org/envs/shared` with the following content:

```terraform
module "kms_keyring" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//1-org/modules/ml_kms_keyring?ref=fe3b1b453906d781d22743782afc92664d517b69"

  keyring_admins = [
    "serviceAccount:${local.projects_step_terraform_service_account_email}"
  ]
  project_id      = module.org_kms.project_id
  keyring_regions = var.keyring_regions
  keyring_name    = var.keyring_name
}
```

After making these modifications to the step, you can follow the README.md procedure for `1-org` step on foundation.

# 2-environment: Create environment level logging keys, logging project and logging bucket

- Create `ml_key_rings.tf` file on `2-environments/modules/env_baseline` path with the following content:

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

locals {
  logging_key_name = module.env_logs.project_id
}

// Creates a keyring with logging key for each region (us-central1, us-east4)
module "kms_keyring" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//2-environment/modules/ml_kms_keyring?ref=fe3b1b453906d781d22743782afc92664d517b69"

  keyring_admins = [
    "serviceAccount:${local.projects_step_terraform_service_account_email}"
  ]
  project_id          = module.env_kms.project_id
  keyring_regions     = var.keyring_regions
  keyring_name        = var.keyring_name
  keys                = [local.logging_key_name]
  kms_prevent_destroy = var.kms_prevent_destroy
}
```

- Create `ml_logging.tf` file on `2-environments/modules/env_baseline` path with the following content:

```terraform
/**
 * Copyright 2021 Google LLC
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

data "google_storage_project_service_account" "gcs_logging_account" {
  project = module.env_logs.project_id
}

/******************************************
  Project for Environment Logging
*****************************************/

module "env_logs" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.0"

  random_project_id        = true
  random_project_id_length = 4
  default_service_account  = "deprivilege"
  name                     = "${local.project_prefix}-${var.environment_code}-logging"
  org_id                   = local.org_id
  billing_account          = local.billing_account
  folder_id                = google_folder.env.id
  activate_apis            = ["logging.googleapis.com", "billingbudgets.googleapis.com", "storage.googleapis.com"]

  labels = {
    environment       = var.env
    application_name  = "env-logging"
    billing_code      = "1234"
    primary_contact   = "example1"
    secondary_contact = "example2"
    business_code     = "abcd"
    env_code          = var.environment_code
  }
  budget_alert_pubsub_topic   = var.project_budget.logging_alert_pubsub_topic
  budget_alert_spent_percents = var.project_budget.logging_alert_spent_percents
  budget_amount               = var.project_budget.logging_budget_amount
  budget_alert_spend_basis    = var.project_budget.logging_budget_alert_spend_basis

}

// Create Bucket for this project
resource "google_storage_bucket" "log_bucket" {
  name                        = "${var.gcs_bucket_prefix}-${module.env_logs.project_id}"
  location                    = var.gcs_logging_bucket_location
  project                     = module.env_logs.project_id
  uniform_bucket_level_access = true

  dynamic "retention_policy" {
    for_each = var.gcs_logging_retention_period != null ? [var.gcs_logging_retention_period] : []
    content {
      is_locked        = var.gcs_logging_retention_period.is_locked
      retention_period = var.gcs_logging_retention_period.retention_period_days * 24 * 60 * 60
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key_iam_member.gcs_logging_key.crypto_key_id #module.kms_keyring.keys_by_region[var.gcs_logging_bucket_location][local.logging_key_name]
  }
}

/******************************************
  Logging Bucket - IAM
*****************************************/
# resource "google_storage_bucket_iam_member" "bucket_logging" {
#   bucket = google_storage_bucket.log_bucket.name
#   role   = "roles/storage.objectCreator"
#   member = "group:cloud-storage-analytics@google.com"
# }

resource "google_kms_crypto_key_iam_member" "gcs_logging_key" {
  crypto_key_id = module.kms_keyring.keys_by_region[var.gcs_logging_bucket_location][local.logging_key_name]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_logging_account.email_address}"
}
```

## `N.B.` Read this before continuing further!!

A logging project will be created in every environment (`development`, `non-production`, `production`) when running this code. This project contains a storage bucket for the purposes of project logging within its respective environment.  This requires the `cloud-storage-analytics@google.com` group permissions for the storage bucket.  Since foundations has more restricted security measures, a domain restriction constraint is enforced.  This restraint will prevent Google service accounts to be added to any permissions.  In order for this terraform code to execute without error, manual intervention must be made to ensure everything applies without issue.

You must disable the contraint, assign the permission on the bucket and then apply the contraint again. This step-by-step presents you with two different options and only one of them should be executed.

The first and the recommended option is making the intervention using `gcloud` cli, as described in **Option 1**. **Option 2** is an alternative to `gcloud` cli and relies on Google Cloud Console.

### Option 1: Use `gcloud` cli to disable/enable organization policy constraint

You will be doing this procedure for each environment (`development`, `non-production` & `production`)

#### `development` environment configuration

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

#### `non-production` environment configuration

1. Configure the following variable below with the value of `gcp-environments` repository path.

```bash
export GCP_ENVIRONMENTS_PATH=INSERT_YOUR_PATH_HERE
```

Make sure your git is checked out to the `non-production` branch by running `git checkout non-production` on `GCP_ENVIRONMENTS_PATH`.

```bash
(cd $GCP_ENVIRONMENTS_PATH && git checkout non-production)
```

2. Retrieve the bucket name and project id from terraform outputs.

```bash
export ENV_LOG_BUCKET_NAME=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/non-production" output -raw env_log_bucket_name)
export ENV_LOG_PROJECT_ID=$(terraform -chdir="$GCP_ENVIRONMENTS_PATH/envs/non-production" output -raw env_log_project_id)
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

#### `production` environment configuration

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

### Option 2: Use Google Cloud Console to disable/enable organization policy constraint

1. On `ml_logging.tf` locate the following lines and uncomment them:

```terraform
resource "google_storage_bucket_iam_member" "bucket_logging" {
  bucket = google_storage_bucket.log_bucket.name
  role   = "roles/storage.objectCreator"
  member = "group:cloud-storage-analytics@google.com"
}
```

2. Under `IAM & Admin`, select `Organization Policies`.  Search for "Domain Restricted Sharing"
![list-policy](imgs/list-policy.png)

3. Select 'Manage Policy'.  This directs you to the Domain Restricted Sharing Edit Policy page.  It will be set at 'Inherit parent's policy'.  Change this to 'Google-managed default'
![edit-policy](imgs/edit-policy.png)

4. Follow the instructions on checking out `development`, `non-production` & `production` branches. Once environments terraform code has successfully applied, edit the policy again and select 'Inherit parent's policy' and Click `SET POLICY`.

After making these modifications, you can follow the README.md procedure for `2-environment` step on foundation, make sure you **change the organization policy after running the steps on foundation**.

# 3-network: Configure private DNS zone for Vertex Workbench Instances

- Create a file named `ml_dns_notebooks.tf` on path `modules/base_env` with the follwing content:

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

module "ml_dns_vertex_ai" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//3-networks-dual-svpc/modules/ml_dns_notebooks?ref=fe3b1b453906d781d22743782afc92664d517b69"

  project_id                         = local.restricted_project_id
  private_service_connect_ip         = var.restricted_private_service_connect_ip
  private_visibility_config_networks = [module.restricted_shared_vpc.network_self_link]
  zone_names = {
    kernels_googleusercontent_zone   = "dz-${var.environment_code}-shared-restricted-kernels-googleusercontent"
    notebooks_googleusercontent_zone = "dz-${var.environment_code}-shared-restricted-notebooks-googleusercontent"
    notebooks_cloudgoogle_zone       = "dz-${var.environment_code}-shared-restricted-notebooks"
  }
}
```

After making these modifications to the step, you can follow the README.md procedure for `3-networks-dual-svpc` step on foundation.

# 4-projects: Create Service Catalog and Artifacts Shared projects and Machine Learning Projects

- choose business unit to deploy
- deploy ml infra projects (common folder)
- create infra pipeline
- deploy ml envs on business unit

# 5-appinfra

- create service catalog and artifacts build triggers
- trigger service catalog and artifacts custom builds
- adjust vpc-sc to your environment

# 6-mlpipeline

- trigger ml infra pipeline, which will create some resources on development environment for the machine learning project
- on dev env run the notebook and adjust it to your environment
- promote the test application to prod and test the deployed model
