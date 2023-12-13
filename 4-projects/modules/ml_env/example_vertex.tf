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

locals {
  kms_sa = [
    "service-${module.learning_project.project_number}@compute-system.iam.gserviceaccount.com",
    "service-${module.learning_project.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com"
  ]
  kms_key_roles = [
    "roles/cloudkms.cryptoKeyEncrypter",
    "roles/cloudkms.cryptoKeyDecrypter",
  ]
}

module "machine_learning_project" {
  source = "../single_project"

  org_id                     = local.org_id
  billing_account            = local.billing_account
  folder_id                  = var.business_unit_folder
  environment                = var.env
  vpc_type                   = "base"
  shared_vpc_host_project_id = local.base_host_project_id
  shared_vpc_subnets         = local.base_subnets_self_links
  project_budget             = var.project_budget
  project_prefix             = local.project_prefix


  // Enabling Cloud Build Deploy to use Service Accounts during the build and give permissions to the SA.
  // The permissions will be the ones necessary for the deployment of the step 5-app-infra
  enable_cloudbuild_deploy = local.enable_cloudbuild_deploy

  # // A map of Service Accounts to use on the infra pipeline (Cloud Build)
  # // Where the key is the repository name ("${var.business_code}-example-app")
  app_infra_pipeline_service_accounts = local.app_infra_pipeline_service_accounts

  // Map for the roles where the key is the repository name ("${var.business_code}-example-app")
  // and the value is the list of roles that this SA need to deploy step 5-app-infra
  sa_roles = {
    "bu3-example-app" = [
      "roles/compute.instanceAdmin.v1",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountUser",
    ]
  }

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "deploymentmanager.googleapis.com",
    "logging.googleapis.com",
    "notebooks.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com"
  ]


  # Metadata
  project_suffix    = "machine-learning"
  application_name  = "${var.business_code}-sample-machine-learning-application"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = var.business_code
}

data "google_storage_project_service_account" "gcs_account" {
  project = module.machine_learning_project.project_id
}

resource "google_kms_crypto_key" "ml_key" {
  name            = module.machine_learning_project.project_name
  key_ring        = local.shared_kms_key_ring
  rotation_period = var.key_rotation_period
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_kms_crypto_key_iam_binding" "encrypt" {
  for_each      = toset(local.kms_key_roles)
  crypto_key_id = google_kms_crypto_key.ml_key.id
  role          = each.key
  members = var.env == "development" ? concat([
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
    ],
    local.kms_sa
  ) : ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "random_string" "bucket_name" {
  length  = 5
  upper   = false
  numeric = true
  lower   = true
  special = false
}

module "gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 4.0"

  project_id         = module.machine_learning_project.project_id
  location           = local.default_region
  name               = "${var.gcs_bucket_prefix}-${module.machine_learning_project.project_id}-${lower(local.default_region)}-cmek-encrypted-${random_string.bucket_name.result}"
  bucket_policy_only = true

  encryption = {
    default_kms_key_name = google_kms_crypto_key.ml_key.id
  }
}
