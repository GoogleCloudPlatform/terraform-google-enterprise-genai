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
}

// Create keyring and keys for this project
module "kms_keyring" {
  source = "../ml_kms_keyring"

  keyring_admins = [
    "serviceAccount:${local.projects_step_terraform_service_account_email}"
  ]
  project_id          = module.env_kms.project_id
  keyring_regions     = var.keyring_regions
  keyring_name        = var.keyring_name
  keys                = [local.logging_key_name]
  kms_prevent_destroy = var.kms_prevent_destroy
}
