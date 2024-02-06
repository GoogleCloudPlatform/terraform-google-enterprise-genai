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

########################
#      Composer        #
########################

module "composer" {
  count  = var.env != "development" ? 1 : 0
  source = "git::https://source.developers.google.com/p/SERVICE-CATALOG-PROJECT-ID/r/service-catalog//modules/composer?ref=main"

  project_id                 = var.project_id
  name                       = var.composer_name
  airflow_config_overrides   = var.composer_airflow_config_overrides
  github_remote_uri          = var.composer_github_remote_uri
  github_app_installation_id = var.composer_github_app_installation_id

  region                       = var.region
  labels                       = var.composer_labels
  maintenance_window           = var.composer_maintenance_window
  env_variables                = var.composer_env_variables
  image_version                = var.composer_image_version
  pypi_packages                = var.composer_pypi_packages
  python_version               = var.composer_python_version
  web_server_allowed_ip_ranges = var.composer_web_server_allowed_ip_ranges

  depends_on = [google_service_account.composer, google_kms_crypto_key_iam_member.service_agent_kms_key_binding]
}

########################
#      Big Query       #
########################

module "big_query" {
  count  = var.env != "development" ? 1 : 0
  source = "git::https://source.developers.google.com/p/SERVICE-CATALOG-PROJECT-ID/r/service-catalog//modules/bigquery?ref=main"

  project_id = var.project_id
  dataset_id = var.big_query_dataset_id

  region                          = var.region
  friendly_name                   = var.big_query_friendly_name
  description                     = var.big_query_description
  default_partition_expiration_ms = var.big_query_default_partition_expiration_ms
  default_table_expiration_ms     = var.big_query_default_table_expiration_ms
  delete_contents_on_destroy      = var.big_query_delete_contents_on_destroy

  depends_on = [google_kms_crypto_key_iam_member.service_agent_kms_key_binding]
}

########################
#      Metadata        #
########################

module "metadata" {
  count  = var.env != "development" ? 1 : 0
  source = "git::https://source.developers.google.com/p/SERVICE-CATALOG-PROJECT-ID/r/service-catalog//modules/metadata?ref=main"

  project_id = var.project_id
  name       = var.metadata_name

  region = var.region

  depends_on = [google_kms_crypto_key_iam_member.service_agent_kms_key_binding]
}

########################
#       Bucket         #
########################

module "bucket" {
  count  = var.env != "development" ? 1 : 0
  source = "git::https://source.developers.google.com/p/SERVICE-CATALOG-PROJECT-ID/r/service-catalog//modules/bucket?ref=main"

  project_id = var.project_id
  name       = var.bucket_name

  region                       = var.region
  dual_region_locations        = var.bucket_dual_region_locations
  force_destroy                = var.bucket_force_destroy
  lifecycle_rules              = var.bucket_lifecycle_rules
  retention_policy             = var.bucket_retention_policy
  object_folder_temporary_hold = var.bucket_object_folder_temporary_hold
  labels                       = var.bucket_labels
  add_random_suffix            = var.bucket_add_random_suffix
  uniform_bucket_level_access  = var.bucket_uniform_bucket_level_access
  storage_class                = var.bucket_storage_class
  requester_pays               = var.bucket_requester_pays
  gcs_bucket_prefix            = var.gcs_bucket_prefix

  depends_on = [google_kms_crypto_key_iam_member.service_agent_kms_key_binding]
}

########################
#      TensorBoard     #
########################

module "tensorboard" {
  count  = var.env != "development" ? 1 : 0
  source = "git::https://source.developers.google.com/p/SERVICE-CATALOG-PROJECT-ID/r/service-catalog//modules/tensorboard?ref=main"

  project_id = var.project_id
  name       = var.tensorboard_name

  region = var.region

  depends_on = [google_kms_crypto_key_iam_member.service_agent_kms_key_binding]
}
