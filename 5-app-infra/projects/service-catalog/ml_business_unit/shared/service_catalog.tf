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

locals {
  region_kms_keyring = [for i in local.shared_keyrings : i if split("/", i)[3] == var.instance_region]
}

data "google_project" "common_svc_catalog" {
  project_id = local.service_catalog_project_id
}

module "service_catalog" {
  source = "../../modules/service_catalog"

  project_id                      = local.service_catalog_project_id
  region                          = var.instance_region
  name                            = local.service_catalog_repo_name
  machine_learning_project_number = local.machine_learning_project_number
  tf_service_catalog_sa_email     = local.tf_service_catalog_sa_email
  bucket_force_destroy            = var.bucket_force_destroy

  log_bucket     = var.log_bucket
  kms_crypto_key = "${one(local.region_kms_keyring)}/cryptoKeys/${data.google_project.common_svc_catalog.name}"
}
