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
  logging_key_name = module.env_logs.project_id
  keyring_admins = [
    "serviceAccount:${local.projects_step_terraform_service_account_email}"
  ]
}

data "google_storage_project_service_account" "gcs_logging_account" {
  project = module.env_logs.project_id
}

// Create keyring and keys for this project
module "kms" {
  for_each = toset(var.keyring_regions)

  source  = "terraform-google-modules/kms/google"
  version = "~> 2.3"

  project_id      = module.env_kms.project_id
  location        = each.value
  keyring         = var.keyring_name
  keys            = [local.logging_key_name]
  prevent_destroy = var.kms_prevent_destroy
}

/******************************************
  KMS - IAM
*****************************************/

resource "google_kms_crypto_key_iam_member" "gcs_logging_key" {
  for_each = module.kms

  crypto_key_id = module.kms[each.key].keys[local.logging_key_name]
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_logging_account.email_address}"
}

resource "google_project_iam_member" "kms_admins" {
  for_each = toset(local.keyring_admins)

  project = module.env_kms.project_id
  role    = "roles/cloudkms.admin"
  member  = each.value
}
