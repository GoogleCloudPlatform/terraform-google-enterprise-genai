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

data "google_compute_default_service_account" "non_prod" {
  project = local.machine_learning_project_id
}

resource "google_service_account" "dataflow_sa" {
  project    = local.machine_learning_project_id
  account_id = "dataflow-sa"
}

resource "google_project_iam_member" "dataflow_sa" {
  for_each = toset([
    "roles/bigquery.admin",
    "roles/dataflow.admin",
    "roles/dataflow.worker",
    "roles/storage.admin",
    "roles/aiplatform.admin",
  ])
  project = local.machine_learning_project_id
  member  = google_service_account.dataflow_sa.member
  role    = each.key
}

resource "google_service_account_iam_member" "impersonate_dataflow" {
  service_account_id = google_service_account.dataflow_sa.id
  role               = "roles/iam.serviceAccountUser"
  member             = data.google_compute_default_service_account.non_prod.member
}

resource "google_service_account" "trigger_sa" {
  project    = local.machine_learning_project_id
  account_id = "trigger-sa"
}

resource "google_storage_bucket_iam_member" "bucket" {
  bucket = module.base_env.bucket.storage_bucket.name
  role   = "roles/storage.admin"
  member = google_service_account.trigger_sa.member
}

resource "google_project_iam_member" "trigger_sa" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/aiplatform.admin"
  ])
  project = local.machine_learning_project_id
  member  = google_service_account.trigger_sa.member
  role    = each.key
}

resource "google_service_account_iam_member" "impersonate" {
  service_account_id = data.google_compute_default_service_account.non_prod.id
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.trigger_sa.member
}

resource "google_artifact_registry_repository_iam_member" "ar_member" {
  for_each = {
    "compute-sa"    = "serviceAccount:${local.non_production_project_number}-compute@developer.gserviceaccount.com",
    "trigger-sa"    = google_service_account.trigger_sa.member,
    "aiplatform-sa" = "serviceAccount:service-${local.non_production_project_number}@gcp-sa-aiplatform-cc.iam.gserviceaccount.com",
  }


  project    = local.common_artifacts_project_id
  location   = var.instance_region
  repository = var.repository_id
  role       = "roles/artifactregistry.reader"
  member     = each.value
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

  kms_keys = local.machine_learning_kms_keys

  // Composer
  composer_enabled = false

  composer_name = "composer"
  composer_airflow_config_overrides = {
    core-dags_are_paused_at_creation = "true"
  }
  composer_github_app_installation_id = var.github_app_installation_id
  composer_github_remote_uri          = var.github_remote_uri

  composer_pypi_packages = {
    google-cloud-bigquery   = ""
    db-dtypes               = ""
    google-cloud-aiplatform = ""
    google-cloud-storage    = ""
    tensorflow              = ""
    # tensorflow-io           = ""
  }

  // BigQuery
  big_query_dataset_id = "census_dataset"

  // Metadata
  metadata_name = "metadata-store-${local.env}"

  // Bucket
  bucket_name = "ml-storage-${random_string.suffix.result}"

  // TensorBoard
  tensorboard_name = "ml-tensorboard-${local.env}"

  log_bucket = local.env_log_bucket
  keyring    = one(local.region_kms_keyring)
}
