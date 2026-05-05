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

module "vertex_ai" {
  source = "../../"

  org_id                             = var.org_id
  folder_id                          = var.parent_folder
  billing_account                    = var.billing_account
  terraform_service_account          = var.terraform_service_account
  instance_region                    = var.default_region
  kms_project_id                     = module.harness.kms_project_id
  kms_project_number                 = module.harness.kms_project_number
  logging_project_id                 = module.harness.logging_project_id
  logging_project_number             = module.harness.logging_project_number
  logging_project_name               = module.harness.logging_project_name
  machine_learning_project_id        = module.harness.machine_learning_project_id
  machine_learning_project_number    = module.harness.machine_learning_project_number
  machine_learning_project_name      = module.harness.machine_learning_project_name
  service_catalog_project_id         = module.harness.service_catalog_project_id
  service_catalog_project_number     = module.harness.service_catalog_project_number
  service_catalog_project_name       = module.harness.service_catalog_project_name
  artifact_publish_project_id        = module.harness.artifact_publish_project_id
  artifact_publish_project_number    = module.harness.artifact_publish_project_number
  artifact_publish_project_name      = module.harness.artifact_publish_project_name
  private_service_connect_ip         = var.private_service_connect_ip
  private_visibility_config_networks = [module.harness.restricted_network_self_link]
  network_name                       = module.harness.machine_learning_network_name
  perimeter_additional_members       = var.perimeter_additional_members
  access_context_manager_policy_id   = var.access_context_manager_policy_id
  enforce_vpcsc                      = var.enforce_vpcsc
  keyring_admins                     = ["serviceAccount:${var.terraform_service_account}"]
  kms_prevent_destroy                = var.kms_prevent_destroy
  bucket_force_destroy               = var.bucket_force_destroy
}
