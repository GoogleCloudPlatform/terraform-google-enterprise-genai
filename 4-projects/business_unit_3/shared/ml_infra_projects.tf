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

module "ml_infra_project" {
  source = "../../modules/ml_infra_projects"

  org_id                                 = local.org_id
  folder_id                              = local.common_folder_name
  billing_account                        = local.billing_account
  environment                            = "common"
  key_rings                              = local.shared_kms_key_ring
  business_code                          = "bu3"
  billing_code                           = "1234"
  primary_contact                        = "example@example.com"
  secondary_contact                      = "example2@example.com"
  cloud_source_artifacts_repo_name       = var.cloud_source_artifacts_repo_name
  cloud_source_service_catalog_repo_name = var.cloud_source_service_catalog_repo_name
  remote_state_bucket                    = var.remote_state_bucket
}
