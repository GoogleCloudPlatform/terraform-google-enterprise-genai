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

module "harness" {
  source = "../../modules/harness"

  org_id                        = var.org_id
  folder_id                     = var.parent_folder
  billing_account               = var.billing_account
  region                        = var.region
  kms_project_name              = var.kms_project_name
  logging_project_name          = var.logging_project_name
  machine_learning_project_name = var.machine_learning_project_name
  artifact_publish_project_name = var.artifact_publish_project_name
  service_catalog_project_name  = var.service_catalog_project_name
  default_region                = var.default_region
  terraform_service_account     = var.terraform_service_account
  bucket_force_destroy          = var.bucket_force_destroy
  project_deletion_policy       = var.project_deletion_policy
}
