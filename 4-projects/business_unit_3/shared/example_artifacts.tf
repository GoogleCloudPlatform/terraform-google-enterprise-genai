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
  artifact_tf_sa_roles = [
    "roles/secretmanager.admin",
    "roles/cloudbuild.builds.editor",
    "roles/artifactregistry.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudbuild.connectionAdmin",
  ]
}
module "app_infra_artifacts_project" {
  source = "../../modules/single_project"
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
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  # Metadata
  project_suffix    = "artifacts"
  application_name  = "app-infra-artifacts"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "bu3"
}

# resource "google_kms_crypto_key" "ml_key" {
#   for_each        = toset(local.shared_kms_key_ring)
#   name            = module.app_infra_artifacts_project[0].project_name
#   key_ring        = each.key
#   rotation_period = var.key_rotation_period
#   lifecycle {
#     prevent_destroy = false
#   }
# }
resource "google_kms_crypto_key_iam_member" "ml_key" {
  for_each      = module.app_infra_cloudbuild_project[0].crypto_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-artifact-publish"]}"
}

resource "google_project_iam_member" "artifact_tf_sa_roles" {
  for_each = toset(local.artifact_tf_sa_roles)
  project  = module.app_infra_artifacts_project[0].project_id
  role     = each.key
  member   = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-artifact-publish"]}"
}

// Add Service Agent for Cloud Build
resource "google_project_iam_member" "artifact_cloudbuild_agent" {
  project = module.app_infra_artifacts_project[0].project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${module.app_infra_artifacts_project[0].project_number}@cloudbuild.gserviceaccount.com"
}
