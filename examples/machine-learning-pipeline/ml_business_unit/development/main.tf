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

data "google_project" "project" {
  project_id = local.machine_learning_project_id
}

resource "google_artifact_registry_repository_iam_member" "member" {
  for_each = toset([
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
    google_service_account.vertex_sa.member
  ])

  project    = local.common_artifacts_project_id
  location   = var.instance_region
  repository = var.repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.key
}

resource "google_service_account" "dataflow_sa" {
  project    = local.machine_learning_project_id
  account_id = "dataflow-sa"
}

resource "google_service_account" "vertex_sa" {
  project    = local.machine_learning_project_id
  account_id = "vertex-sa"
}

resource "google_service_account" "vertex_model" {
  project    = local.machine_learning_project_id
  account_id = "vertex-model"
}

resource "google_project_iam_member" "dataflow_sa" {
  for_each = toset(local.roles)
  project  = local.machine_learning_project_id
  member   = google_service_account.dataflow_sa.member
  role     = each.key
}

resource "google_project_iam_member" "vertex_sa" {
  for_each = toset(local.roles)
  project  = local.machine_learning_project_id
  member   = google_service_account.vertex_sa.member
  role     = each.key
}

resource "google_service_account_iam_member" "compute_impersonate_vertex" {
  service_account_id = google_service_account.vertex_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_service_account_iam_member" "vertex_impersonate_model" {
  service_account_id = google_service_account.vertex_model.id
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.vertex_sa.member
}

resource "google_service_account_iam_member" "impersonate_dataflow" {
  service_account_id = google_service_account.dataflow_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.vertex_sa.member
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "base_env" {
  source = "../../modules/base_env"

  env                           = local.env
  environment_code              = local.environment_code
  business_code                 = local.business_code
  non_production_project_id     = local.non_production_project_id
  non_production_project_number = local.non_production_project_number
  production_project_id         = local.production_project_id
  production_project_number     = local.production_project_number
  project_id                    = local.machine_learning_project_id
  kms_keys                      = local.machine_learning_kms_keys

  bucket_name = "ml-storage-${random_string.suffix.result}"

  log_bucket = local.env_log_bucket
  keyring    = one(local.region_kms_keyring)
}
