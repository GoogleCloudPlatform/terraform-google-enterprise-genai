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
  key_rings                  = local.environments_kms_key_ring
  remote_state_bucket        = var.remote_state_bucket
  // Enabling Cloud Build Deploy to use Service Accounts during the build and give permissions to the SA.
  // The permissions will be the ones necessary for the deployment of the step 5-app-infra
  enable_cloudbuild_deploy = local.enable_cloudbuild_deploy

  # // A map of Service Accounts to use on the infra pipeline (Cloud Build)
  # // Where the key is the repository name ("${var.business_code}-example-app")
  app_infra_pipeline_service_accounts = local.app_infra_pipeline_service_accounts

  // Map for the roles where the key is the repository name ("${var.business_code}-example-app")
  // and the value is the list of roles that this SA need to deploy step 5-app-infra
  sa_roles = {
    "bu3-artifact-publish" = [
      "roles/compute.instanceAdmin.v1",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountUser",
    ],
    "bu3-service-catalog" = [
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
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
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

# resource "google_project_iam_member" "project_roles" {
#   project = module.machine_learning_project.project_id
#   role    = "roles/storage.legacyObjectReader"
#   member  = "serviceAccount:${module.machine_learning_project.project_number}@cloudbuild.gserviceaccount.com"
# }

# resource "google_project_service_identity" "secret_manager" {
#   provider = google-beta
#   project  = module.machine_learning_project.project_id
#   service  = "secretmanager.googleapis.com"
# }
# resource "google_kms_crypto_key" "ml_key" {
#   for_each        = toset(local.shared_kms_key_ring)
#   name            = module.machine_learning_project.project_name
#   key_ring        = each.key
#   rotation_period = var.key_rotation_period
#   lifecycle {
#     prevent_destroy = false
#   }
# }


# // Change to iam member, give cloudbuild sa  'roles/cloudkms.admin' = just for development!

resource "google_kms_crypto_key_iam_member" "dev_ml_key" {
  for_each      = var.env == "development" ? toset(keys(module.machine_learning_project.crypto_key)) : toset([])
  crypto_key_id = module.machine_learning_project.crypto_key[each.key].id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${module.machine_learning_project.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "ml_key" {
  for_each      = module.machine_learning_project.crypto_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}


// Big Query
data "google_bigquery_default_service_account" "bq_sa" {
  project = module.machine_learning_project.project_id
}
resource "google_kms_crypto_key_iam_member" "big_query_ml_key" {
  for_each      = module.machine_learning_project.crypto_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_bigquery_default_service_account.bq_sa.email}"
}
