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
  kms_project_id                     = module.kms_project.project_id
  kms_project_number                 = module.kms_project.project_number
  logging_project_id                 = module.logging_project.project_id
  logging_project_number             = module.logging_project.project_number
  logging_project_name               = module.logging_project.project_name
  machine_learning_project_id        = module.machine_learning_project.project_id
  machine_learning_project_number    = module.machine_learning_project.project_number
  machine_learning_project_name      = module.machine_learning_project.project_name
  service_catalog_project_id         = module.service_catalog_project.project_id
  service_catalog_project_number     = module.service_catalog_project.project_number
  service_catalog_project_name       = module.service_catalog_project.project_name
  artifact_publish_project_id        = module.artifact_publish_project.project_id
  artifact_publish_project_number    = module.artifact_publish_project.project_number
  artifact_publish_project_name      = module.artifact_publish_project.project_name
  private_service_connect_ip         = var.private_service_connect_ip
  private_visibility_config_networks = [module.network.network_self_link]
  network_name                       = module.network.network_name
  perimeter_additional_members       = var.perimeter_additional_members
  access_context_manager_policy_id   = var.access_context_manager_policy_id
  enforce_vpcsc                      = var.enforce_vpcsc
  keyring_admins                     = ["serviceAccount:${var.terraform_service_account}"]
  kms_prevent_destroy                = var.kms_prevent_destroy
  bucket_force_destroy               = var.bucket_force_destroy
}
