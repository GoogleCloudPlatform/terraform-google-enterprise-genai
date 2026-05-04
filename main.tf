/**
 * Copyright 2026 Google LLC
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
  region_kms_keyring  = [for k, m in module.kms_keyrings : k if split("/", m.keyring)[3] == var.instance_region]
  gcs_logging_kms_key = module.kms_keyrings[var.gcs_logging_bucket_location].keys[var.logging_project_name]

  keyrings = { for region, mod in module.kms_keyrings : region => mod.keyring }
}

/******************************************
  Org Policies
*****************************************/

module "ml_organization_policies" {
  source = "./modules/ml_org_policies"

  org_id    = var.org_id
  folder_id = var.folder_id

  allowed_locations = [
    "in:us-locations"
  ]

  allowed_vertex_vpc_networks = {
    parent_type = "project"
    ids         = [var.machine_learning_project_id],
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

/******************************************
  Key Keys
*****************************************/

module "kms_keyrings" {
  source   = "terraform-google-modules/kms/google"
  version  = "~> 4.0"
  for_each = toset(var.keyring_regions)

  project_id      = var.kms_project_id
  keyring         = var.keyring_name
  location        = each.key
  prevent_destroy = var.kms_prevent_destroy

  keys = [
    var.logging_project_name,
    var.service_catalog_project_name,
    var.artifact_publish_project_name,
    var.machine_learning_project_name
  ]
}

resource "google_project_iam_member" "kms_admins" {
  for_each = toset(var.keyring_admins)

  project = var.kms_project_id
  role    = "roles/cloudkms.admin"
  member  = each.value
}

/******************************************
  Log Bucket
*****************************************/

data "google_storage_project_service_account" "gcs_logging_account" {
  project = var.logging_project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_logging_key" {
  crypto_key_id = local.gcs_logging_kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_logging_account.email_address}"
}

module "ml_logging" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 12.0"

  name       = "${var.gcs_bucket_prefix}-${var.logging_project_id}"
  location   = var.gcs_logging_bucket_location
  project_id = var.logging_project_id

  encryption = {
    default_kms_key_name = local.gcs_logging_kms_key
  }

  depends_on = [
    google_kms_crypto_key_iam_member.gcs_logging_key
  ]
}

/******************************************
  DNS Notebooks
*****************************************/

module "ml_dns_vertex_ai" {
  source = "./modules/ml_dns_notebooks"

  project_id                         = var.machine_learning_project_id
  private_service_connect_ip         = "10.10.64.5"
  private_visibility_config_networks = var.restricted_network_self_link
  zone_names = {
    kernels_googleusercontent_zone   = "dz-shared-restricted-kernels-googleusercontent"
    notebooks_googleusercontent_zone = "dz-shared-restricted-notebooks-googleusercontent"
    notebooks_cloudgoogle_zone       = "dz-shared-restricted-notebooks"
  }
}

resource "time_sleep" "wait_for_kms" {
  create_duration = "60"

  depends_on = [module.kms_keyrings]
}

/******************************************
  Machine Learning project
*****************************************/

module "machine_learning_env" {
  source = "./modules/ml_env"

  kms_project_id                   = var.kms_project_id
  machine_learning_project_id      = var.machine_learning_project_id
  machine_learning_project_number  = var.machine_learning_project_number
  machine_learning_project_name    = var.machine_learning_project_name
  key_rings                        = local.keyrings
  keyring_regions                  = var.keyring_regions
  service_catalog_project_id       = var.service_catalog_project_id
  cloud_source_artifacts_repo_name = var.cloud_source_service_catalog_repo_name
  artifact_publish_project_id      = var.artifact_publish_project_id
  machine_learning_pipeline_sa     = var.terraform_service_account
  kms_crypto_key                   = module.kms_keyrings[one(local.region_kms_keyring)].keys[var.machine_learning_project_name]

  depends_on = [time_sleep.wait_for_kms]
}

/******************************************
  Artifact Publish
*****************************************/

module "artifact_publish" {
  source = "./modules/publish_artifacts"

  description                 = "Publish Artifacts for ML Projects"
  project_id                  = var.artifact_publish_project_id
  project_name                = var.artifact_publish_project_name
  name                        = var.cloud_source_artifacts_repo_name
  format                      = "DOCKER"
  region                      = var.instance_region
  bucket_force_destroy        = var.bucket_force_destroy
  keyring_regions             = var.keyring_regions
  key_rings                   = local.keyrings
  artifacts_infra_pipeline_sa = var.terraform_service_account
  cleanup_policies = [{
    id     = "keep-tagged-release"
    action = "KEEP"
    condition = [
      {
        tag_state             = "TAGGED",
        tag_prefixes          = ["release"],
        package_name_prefixes = ["webapp", "mobile"]
      }
    ]
  }]

  kms_crypto_key = module.kms_keyrings[one(local.region_kms_keyring)].keys[var.artifact_publish_project_name]

  depends_on = [time_sleep.wait_for_kms]
}

module "service_catalog" {
  source = "./modules/service_catalog"

  project_id                      = var.service_catalog_project_id
  project_name                    = var.service_catalog_project_name
  region                          = var.instance_region
  name                            = var.cloud_source_service_catalog_repo_name
  machine_learning_project_number = var.machine_learning_project_number
  service_catalog_pipeline_sa     = var.terraform_service_account
  bucket_force_destroy            = var.bucket_force_destroy
  keyring_regions                 = var.keyring_regions
  key_rings                       = local.keyrings

  log_bucket     = module.ml_logging.name
  kms_crypto_key = module.kms_keyrings[one(local.region_kms_keyring)].keys[var.service_catalog_project_name]

  depends_on = [time_sleep.wait_for_kms]
}
