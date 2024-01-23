########################
#      Composer        #
########################

module "composer" {
  count  = var.env != "development" ? 1 : 0
  source = "../composer"

  project_id                 = var.project_id
  name                       = var.composer_name
  airflow_config_overrides   = var.composer_airflow_config_overrides
  github_api_token           = var.composer_github_api_token
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
}

########################
#      Big Query       #
########################

module "big_query" {
  count  = var.env != "development" ? 1 : 0
  source = "../bigquery"

  project_id = var.project_id
  dataset_id = var.big_query_dataset_id

  region                          = var.region
  friendly_name                   = var.big_query_friendly_name
  description                     = var.big_query_description
  default_partition_expiration_ms = var.big_query_default_partition_expiration_ms
  default_table_expiration_ms     = var.big_query_default_table_expiration_ms
  delete_contents_on_destroy      = var.big_query_delete_contents_on_destroy
}

########################
#      Metadata        #
########################

module "metadata" {
  count  = var.env != "development" ? 1 : 0
  source = "../metadata"

  project_id = var.project_id
  name       = var.metadata_name

  region = var.region
}

########################
#       Bucket         #
########################

module "bucket" {
  count  = var.env != "development" ? 1 : 0
  source = "../bucket"

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
}

########################
#      TensorBoard     #
########################

module "tensorboard" {
  count  = var.env != "development" ? 1 : 0
  source = "../tensorboard"

  project_id = var.project_id
  name       = var.tensorboard_name

  region = var.region
}
