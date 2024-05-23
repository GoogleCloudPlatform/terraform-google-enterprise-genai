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
    gcp-policies-app-infra
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
gcp-policies-app-infra
gcp-projects
terraform-google-enterprise-genai
```

## Policies

### Update `gcloud terraform vet` policies

the first step is to update the `gcloud terraform vet` policies constraints to allow usage of the APIs needed by the Blueprint.
The constraints are located in the two policies repositories:

- `gcp-policies`
- `gcp-policies-app-infra`

All changes below must be made to both repositories:

- Create file `cmek_settings.yaml` on `policies/constraints` path with the following content:

```yaml
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPCMEKSettingsConstraintV1
metadata:
  name: cmek_rotation
  annotations:
    description: Checks multiple CMEK key settings (protection level, algorithm, purpose,
      rotation period).
spec:
  severity: high
  match:
    ancestries:
    - "organizations/**"
  parameters:
    # Optionally specify the required key rotation period.  Default is 90 days
    # Valid time units are  "ns", "us", "ms", "s", "m", "h"
    # This is 90 days
    rotation_period: 2160h
    algorithm: GOOGLE_SYMMETRIC_ENCRYPTION
    purpose: ENCRYPT_DECRYPT
    protection_level: SOFTWARE
```

- Create file `network_enable_firewall_logs.yaml` on `policies/constraints` path with the following content:

```yaml
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPNetworkEnableFirewallLogsConstraintV1
metadata:
  name: enable-network-firewall-logs
  annotations:
    description: Ensure Firewall logs is enabled for every firewall in VPC Network
    bundles.validator.forsetisecurity.org/healthcare-baseline-v1: security
spec:
  severity: high
  match:
    ancestries:
    - "organizations/**"
  parameters: {}
```

- Create file `require_dnssec.yaml` file on `policies/constraints` path with the following content:

```yaml
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPDNSSECConstraintV1
metadata:
  name: require_dnssec
  annotations:
    description: Checks that DNSSEC is enabled for a Cloud DNS managed zone.
spec:
  severity: high
  parameters: {}
```

- Create file `storage_logging.yaml` on `policies/constraints` path with the following content:

```yaml
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
apiVersion: constraints.gatekeeper.sh/v1alpha1
kind: GCPStorageLoggingConstraintV1
metadata:
  name: storage_logging
  annotations:
    description: Ensure storage logs are delivered to a separate bucket
spec:
  severity: high
  match:
    ancestries:
    - "organizations/**"
    excludedAncestries: [] # optional, default is no exclusions
  parameters: {}
```

- On `serviceusage_allow_basic_apis.yaml` add the following apis:

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

Add files to tracked on git:

```bash
git add policies/constraints/*.yaml
```

Commit changes on `gcp-policies` and `gcp-policies-app-infra` repositories, and push the code.

## 1-org: Create Machine Learning Organization Policies and Organization Level Keys

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

## 2-environment: Create environment level logging keys, logging project and logging bucket

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

### `N.B.` Read this before continuing further

A logging project will be created in every environment (`development`, `non-production`, `production`) when running this code. This project contains a storage bucket for the purposes of project logging within its respective environment.  This requires the `cloud-storage-analytics@google.com` group permissions for the storage bucket.  Since foundations has more restricted security measures, a domain restriction constraint is enforced.  This restraint will prevent the google cloud-storage-analytics group to be added to any permissions.  In order for this terraform code to execute without error, manual intervention must be made to ensure everything applies without issue.

You must disable the contraint, assign the permission on the bucket and then apply the contraint again. This step-by-step presents you with two different options and only one of them should be executed.

The first and the recommended option is making the intervention using `gcloud` cli, as described in **Option 1**.

**Option 2** is an alternative to `gcloud` cli and relies on Google Cloud Console.

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

## 3-network: Configure private DNS zone for Vertex Workbench Instances

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

- Add projects to regular_service_perimeter
- Create firewall rules to allow all ingress from specific ranges
- Enable NAT

## 4-projects: Create Service Catalog and Artifacts Shared projects and Machine Learning Projects

First of all you should choose a Business Unit to deploy this application, in the case of this tutorial we are using `ml_business_unit` as an example.

### Create Machine Learning Business Unit (ML_BU)

 ```bash
   #copy the business_unit_1 folder and it's contents to a new folder ml_business_unit
   cp -r  business_unit_1 ml_business_unit

   # search all files under the folder `ml_business_unit` and replace strings for business_unit_1 with strings for ml_business_unit
   grep -rl bu1 ml_business_unit/ | xargs sed -i 's/bu1/ml_bu/g'
   grep -rl business_unit_1 ml_business_unit/ | xargs sed -i 's/business_unit_1/ml_business_unit/g'
   ```

### Infra Pipeline Modifications

- Open `ml_business_unit/shared/variables.tf` and add the following variables:

```terraform
variable "location_gcs" {
  description = "Case-Sensitive Location for GCS Bucket"
  type        = string
  default     = "US"
}

variable "location_kms" {
  description = "Case-Sensitive Location for KMS Keyring"
  type        = string
  default     = "us"
}

variable "keyring_name" {
  description = "Name to be used for KMS Keyring"
  type        = string
  default     = "sample-keyring"
}

variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for GCS Bucket"
  type        = string
  default     = "bkt"
}

variable "key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key"
  type        = string
  default     = "7776000s"
}

variable "cloud_source_service_catalog_repo_name" {
  description = "Name to give the cloud source repository for Service Catalog"
  type        = string
}

variable "cloud_source_artifacts_repo_name" {
  description = "Name to give the could source repository for Artifacts"
  type        = string
}

variable "prevent_destroy" {
  description = "Prevent Project Key destruction."
  type        = bool
  default     = true
}
```

- Open `ml_business_unit/shared/example_infra_pipeline.tf` and replace its content with:

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
  repo_names = [
    "ml_bu-artifact-publish",
    "ml_bu-service-catalog",
    "ml_bu-machine-learning",
  ]
}

module "app_infra_cloudbuild_project" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//4-projects/modules/single_project?ref=fe3b1b453906d781d22743782afc92664d517b69"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id              = local.org_id
  billing_account     = local.billing_account
  folder_id           = local.common_folder_name
  environment         = "common"
  project_budget      = var.project_budget
  project_prefix      = local.project_prefix
  key_rings           = local.shared_kms_key_ring
  remote_state_bucket = var.remote_state_bucket
  activate_apis = [
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
  ]
  # Metadata
  project_suffix    = "infra-pipeline"
  application_name  = "app-infra-pipelines"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "ml_bu"
}

module "infra_pipelines" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//4-projects/modules/infra_pipelines?ref=fe3b1b453906d781d22743782afc92664d517b69"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id                      = local.org_id
  cloudbuild_project_id       = module.app_infra_cloudbuild_project[0].project_id
  cloud_builder_artifact_repo = local.cloud_builder_artifact_repo
  remote_tfstate_bucket       = local.projects_remote_bucket_tfstate
  billing_account             = local.billing_account
  default_region              = var.default_region
  app_infra_repos             = local.repo_names
  private_worker_pool_id      = local.cloud_build_private_worker_pool_id
}

resource "google_kms_key_ring_iam_member" "key_ring" {
  for_each    = { for k in flatten([for kms in local.shared_kms_key_ring : [for name, email in module.infra_pipelines[0].terraform_service_accounts : { key = "${kms}--${name}", kms = kms, email = email }]]) : k.key => k }
  key_ring_id = each.value.kms
  role        = "roles/cloudkms.admin"
  member      = "serviceAccount:${each.value.email}"
}

/**
 * When Jenkins CICD is used for deployment this resource
 * is created to terraform validation works.
 * Without this resource, this module creates zero resources
 * and it breaks terraform validation throwing the error below:
 * ERROR: [Terraform plan json does not contain resource_changes key]
 */
resource "null_resource" "jenkins_cicd" {
  count = !local.enable_cloudbuild_deploy ? 1 : 0
}
```

- On `ml_business_unit/shared/outputs.tf` add the following outputs:

```terraform
output "service_catalog_project_id" {
  description = "Service Catalog Project ID."
  value       = module.ml_infra_project.service_catalog_project_id
}

output "common_artifacts_project_id" {
  description = "App Infra Artifacts Project ID"
  value       = module.ml_infra_project.common_artifacts_project_id
}

output "service_catalog_repo_name" {
  description = "The name of the Service Catalog repository"
  value       = module.ml_infra_project.service_catalog_repo_name
}

output "service_catalog_repo_id" {
  description = "ID of the Service Catalog repository"
  value       = module.ml_infra_project.service_catalog_repo_id
}

output "artifacts_repo_name" {
  description = "The name of the Artifacts repository"
  value       = module.ml_infra_project.artifacts_repo_name
}

output "artifacts_repo_id" {
  description = "ID of the Artifacts repository"
  value       = module.ml_infra_project.artifacts_repo_id
}
```

- Open `ml_business_unit/shared/remote.tf` and replace it with the following content:

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
  org_id                             = data.terraform_remote_state.bootstrap.outputs.common_config.org_id
  parent_folder                      = data.terraform_remote_state.bootstrap.outputs.common_config.parent_folder
  parent                             = data.terraform_remote_state.bootstrap.outputs.common_config.parent_id
  location_gcs                       = try(data.terraform_remote_state.bootstrap.outputs.common_config.default_region, var.location_gcs)
  billing_account                    = data.terraform_remote_state.bootstrap.outputs.common_config.billing_account
  common_folder_name                 = data.terraform_remote_state.org.outputs.common_folder_name
  common_kms_project_id              = data.terraform_remote_state.org.outputs.org_kms_project_id
  default_region                     = data.terraform_remote_state.bootstrap.outputs.common_config.default_region
  project_prefix                     = data.terraform_remote_state.bootstrap.outputs.common_config.project_prefix
  folder_prefix                      = data.terraform_remote_state.bootstrap.outputs.common_config.folder_prefix
  projects_remote_bucket_tfstate     = data.terraform_remote_state.bootstrap.outputs.projects_gcs_bucket_tfstate
  cloud_build_private_worker_pool_id = try(data.terraform_remote_state.bootstrap.outputs.cloud_build_private_worker_pool_id, "")
  cloud_builder_artifact_repo        = try(data.terraform_remote_state.bootstrap.outputs.cloud_builder_artifact_repo, "")
  enable_cloudbuild_deploy           = local.cloud_builder_artifact_repo != ""
  shared_kms_key_ring                = data.terraform_remote_state.org.outputs.key_rings
}

data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/bootstrap/state"
  }
}

data "terraform_remote_state" "org" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/org/state"
  }
}
```

- Create `ml_infra_projects.tf` file on `ml_business_unit/shared` with the following content:

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

module "ml_infra_project" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//4-projects/modules/ml_infra_projects?ref=fe3b1b453906d781d22743782afc92664d517b69"

  org_id                                 = local.org_id
  folder_id                              = local.common_folder_name
  billing_account                        = local.billing_account
  environment                            = "common"
  key_rings                              = local.shared_kms_key_ring
  business_code                          = "ml_bu"
  billing_code                           = "1234"
  primary_contact                        = "example@example.com"
  secondary_contact                      = "example2@example.com"
  cloud_source_artifacts_repo_name       = var.cloud_source_artifacts_repo_name
  cloud_source_service_catalog_repo_name = var.cloud_source_service_catalog_repo_name
  remote_state_bucket                    = var.remote_state_bucket
  artifacts_infra_pipeline_sa            = module.infra_pipelines[0].terraform_service_accounts["ml_bu-artifact-publish"]
  service_catalog_infra_pipeline_sa      = module.infra_pipelines[0].terraform_service_accounts["ml_bu-service-catalog"]
  environment_kms_project_id             = ""
  prevent_destroy                        = var.prevent_destroy
}
```

### Modify Environments for Machine Learning Business Unit

Perform these modifications for `development`, `non-production` and `production` subfolders on `ml_business_unit`.

1. Edit `main.tf` and replace it's contents with the following:

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

    module "bu_folder" {
      source              = "../../modules/env_folders"
      business_code       = local.business_code
      remote_state_bucket = var.remote_state_bucket
      env                 = var.env
    }

    module "ml_env" {
      source = "../../modules/ml_env"

      env                  = var.env
      business_code        = local.business_code
      business_unit        = local.business_unit
      remote_state_bucket  = var.remote_state_bucket
      location_gcs         = var.location_gcs
      tfc_org_name         = var.tfc_org_name
      business_unit_folder = module.bu_folder.business_unit_folder
    }
    ```

2. Edit `outputs.tf` and replace it's contents with the following:

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

    output "machine_learning_project_id" {
      description = "Project machine learning project."
      value       = module.ml_env.machine_learning_project_id
    }

    output "machine_learning_project_number" {
      description = "Project number of machine learning project."
      value       = module.ml_env.machine_learning_project_number
    }

    output "machine_learning_kms_keys" {
      description = "Key ID for the machine learning project."
      value       = module.ml_env.machine_learning_kms_keys
    }

    output "enable_cloudbuild_deploy" {
      description = "Enable infra deployment using Cloud Build."
      value       = local.enable_cloudbuild_deploy
    }
    ```

3. Edit `variables.tf` and replace it's contents with the following:

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

    variable "env" {
      description = "The environment this deployment belongs to (ie. development)"
      type        = string
    }
    variable "default_region" {
      description = "Default region to create resources where applicable."
      type        = string
      default     = "us-central1"
    }

    variable "remote_state_bucket" {
      description = "Backend bucket to load Terraform Remote State Data from previous steps."
      type        = string
    }

    variable "location_kms" {
      description = "Case-Sensitive Location for KMS Keyring (Should be same region as the GCS Bucket)"
      type        = string
      default     = "us"
    }

    variable "location_gcs" {
      description = "Case-Sensitive Location for GCS Bucket (Should be same region as the KMS Keyring)"
      type        = string
      default     = "US"
    }

    variable "peering_module_depends_on" {
      description = "List of modules or resources peering module depends on."
      type        = list(any)
      default     = []
    }

    variable "tfc_org_name" {
      description = "Name of the TFC organization."
      type        = string
      default     = ""
    }

    variable "project_budget" {
      description = <<EOT
      Budget configuration.
      budget_amount: The amount to use as the budget.
      alert_spent_percents: A list of percentages of the budget to alert on when threshold is exceeded.
      alert_pubsub_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.
      alert_spend_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default).
      EOT
      type = object({
        budget_amount        = optional(number, 1000)
        alert_spent_percents = optional(list(number), [1.2])
        alert_pubsub_topic   = optional(string, null)
        alert_spend_basis    = optional(string, "FORECASTED_SPEND")
      })
      default = {}
    }

    variable "key_rotation_period" {
      description = "Rotation period in seconds to be used for KMS Key"
      type        = string
      default     = "7776000s"
    }
    ```

4. Create `locals.tf` file with the following code:

    ```terraform
    # Copyright 2024 Google LLC
    #
    # Licensed under the Apache License, Version 2.0 (the "License");
    # you may not use this file except in compliance with the License.
    # You may obtain a copy of the License at
    #
    #     https://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
    #
    locals {
      repo_name     = "bu3-composer"
      business_code = "bu3"
      business_unit = "business_unit_3"
    }
    ```

5. Create `remote.tf` file with the following content:

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
      org_id                             = data.terraform_remote_state.bootstrap.outputs.common_config.org_id
      parent_folder                      = data.terraform_remote_state.bootstrap.outputs.common_config.parent_folder
      parent                             = data.terraform_remote_state.bootstrap.outputs.common_config.parent_id
      location_gcs                       = try(data.terraform_remote_state.bootstrap.outputs.common_config.default_region, var.location_gcs)
      billing_account                    = data.terraform_remote_state.bootstrap.outputs.common_config.billing_account
      common_folder_name                 = data.terraform_remote_state.org.outputs.common_folder_name
      common_kms_project_id              = data.terraform_remote_state.org.outputs.org_kms_project_id
      default_region                     = data.terraform_remote_state.bootstrap.outputs.common_config.default_region
      project_prefix                     = data.terraform_remote_state.bootstrap.outputs.common_config.project_prefix
      folder_prefix                      = data.terraform_remote_state.bootstrap.outputs.common_config.folder_prefix
      projects_remote_bucket_tfstate     = data.terraform_remote_state.bootstrap.outputs.projects_gcs_bucket_tfstate
      cloud_build_private_worker_pool_id = try(data.terraform_remote_state.bootstrap.outputs.cloud_build_private_worker_pool_id, "")
      cloud_builder_artifact_repo        = try(data.terraform_remote_state.bootstrap.outputs.cloud_builder_artifact_repo, "")
      enable_cloudbuild_deploy           = local.cloud_builder_artifact_repo != ""
      environment_kms_key_ring           = data.terraform_remote_state.environments_env.outputs.key_rings
    }

    data "terraform_remote_state" "bootstrap" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/bootstrap/state"
      }
    }

    data "terraform_remote_state" "org" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/org/state"
      }
    }

    data "terraform_remote_state" "environments_env" {
      backend = "gcs"

      config = {
        bucket = var.remote_state_bucket
        prefix = "terraform/environments/${var.env}"
      }
    }
    ```

## 5-appinfra

- create service catalog and artifacts build triggers
- trigger service catalog and artifacts custom builds
- adjust vpc-sc to your environment

## 6-mlpipeline

- trigger ml infra pipeline, which will create some resources on development environment for the machine learning project
- on dev env run the notebook and adjust it to your environment
- promote the test application to prod and test the deployed model
