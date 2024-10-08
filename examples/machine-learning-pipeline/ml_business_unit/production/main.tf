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
  composer_name = "composer"
  composer_airflow_config_overrides = {
    core-dags_are_paused_at_creation = "true"
  }

  composer_github_app_installation_id = var.github_app_installation_id
  composer_github_remote_uri          = var.github_remote_uri

  composer_pypi_packages = {
    tensorflow              = ""
    google-cloud-bigquery   = ""
    db-dtypes               = ""
    google-cloud-aiplatform = ""
    google-cloud-storage    = ""
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
