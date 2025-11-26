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
  app_infra_sa = local.enable_cloudbuild_deploy ? try(module.infra_pipelines[0].terraform_service_accounts, {}) : {}

  artifacts_pipeline_sa       = try(local.app_infra_sa["ml-artifact-publish"], null)
  service_catalog_pipeline_sa = try(local.app_infra_sa["ml-service-catalog"], null)
}

module "ml_infra_projects" {
  source = "../../modules/ml_infra_projects"

  org_id                                 = local.org_id
  folder_id                              = local.common_folder_name
  billing_account                        = local.billing_account
  environment                            = "common"
  key_rings                              = local.shared_kms_key_ring
  business_code                          = "ml"
  billing_code                           = "1234"
  primary_contact                        = "example@example.com"
  secondary_contact                      = "example2@example.com"
  cloud_source_artifacts_repo_name       = var.cloud_source_artifacts_repo_name
  cloud_source_service_catalog_repo_name = var.cloud_source_service_catalog_repo_name
  remote_state_bucket                    = var.remote_state_bucket
  artifacts_infra_pipeline_sa            = local.artifacts_pipeline_sa
  service_catalog_infra_pipeline_sa      = local.service_catalog_pipeline_sa
  environment_kms_project_id             = ""
  prevent_destroy                        = var.prevent_destroy
  enable_cloudbuild_deploy               = local.enable_cloudbuild_deploy
}
