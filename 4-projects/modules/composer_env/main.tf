/**
 * Copyright 2022 Google LLC
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

# locals {
#   service_agents = [
#     "artifactregistry.googleapis.com",
#     "pubsub.googleapis.com",
#     "storage.googleapis.com",
#     "secretmanager.googleapis.com",
#   ]
# }
module "app_cloudbuild_project" {
  source = "../single_project"

  org_id              = local.org_id
  billing_account     = local.billing_account
  folder_id           = var.folder_id
  environment         = var.env
  project_budget      = var.project_budget
  project_prefix      = local.project_prefix
  key_rings           = var.shared_kms_key_ring
  remote_state_bucket = var.remote_state_bucket

  activate_apis = [
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "composer.googleapis.com",
    "sourcerepo.googleapis.com",
    "containerscanning.googleapis.com",
    "container.googleapis.com",
    "pubsub.googleapis.com"
  ]


  # Metadata
  project_suffix    = var.project_suffix
  application_name  = var.application_name
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = var.business_code

  // Enabling Cloud Build Deploy to use Service Accounts during the build and give permissions to the SA.
  // The permissions will be the ones necessary for the deployment of the step 5-app-infra
  enable_cloudbuild_deploy = local.enable_cloudbuild_deploy

  # // A map of Service Accounts to use on the infra pipeline (Cloud Build)
  # // Where the key is the repository name ("${var.business_code}-example-app")
  app_infra_pipeline_service_accounts = local.app_infra_pipeline_service_accounts

  // Map for the roles where the key is the repository name ("${var.business_code}-example-app")
  // and the value is the list of roles that this SA need to deploy step 5-app-infra
  sa_roles = {
    "${var.repo_name}" = [
      "roles/compute.instanceAdmin.v1",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountUser",
      "roles/secretmanager.admin",
      "roles/cloudbuild.builds.editor",
      "roles/artifactregistry.admin",
      "roles/cloudbuild.connectionAdmin",
      "roles/composer.admin",
      "roles/iam.roleAdmin",
      "roles/iam.securityAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.admin",
    ],
  }
}

# resource "google_kms_crypto_key_iam_member" "app_key" {
#   for_each      = module.app_cloudbuild_project.crypto_key
#   crypto_key_id = each.value.id
#   role          = "roles/cloudkms.admin"
#   member        = "serviceAccount:${local.app_infra_pipeline_service_accounts[var.repo_name]}"
# }

# // Add Secret Manager Service Agent to key with encrypt/decrypt permissions
# resource "google_kms_crypto_key_iam_member" "secretmanager_agent" {
#   for_each      = module.app_cloudbuild_project.crypto_key
#   crypto_key_id = each.value.id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:${google_project_service_identity.secretmanager_agent.email}"
# }

resource "google_project_iam_member" "cloudbuild_agent" {
  project = module.app_cloudbuild_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.app_cloudbuild_project.project_number}@cloudbuild.gserviceaccount.com"
}
