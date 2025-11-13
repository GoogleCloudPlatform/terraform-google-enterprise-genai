/**
 * Copyright 2022 Google LLC
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
  org_id                              = data.terraform_remote_state.bootstrap.outputs.common_config.org_id
  parent_folder                       = data.terraform_remote_state.bootstrap.outputs.common_config.parent_folder
  parent                              = data.terraform_remote_state.bootstrap.outputs.common_config.parent_id
  projects_backend_bucket             = data.terraform_remote_state.bootstrap.outputs.projects_gcs_bucket_tfstate
  location_gcs                        = try(data.terraform_remote_state.bootstrap.outputs.common_config.default_region, var.location_gcs)
  billing_account                     = data.terraform_remote_state.bootstrap.outputs.common_config.billing_account
  default_region                      = data.terraform_remote_state.bootstrap.outputs.common_config.default_region
  project_prefix                      = data.terraform_remote_state.bootstrap.outputs.common_config.project_prefix
  projects_remote_bucket_tfstate      = data.terraform_remote_state.bootstrap.outputs.projects_gcs_bucket_tfstate
  cloud_build_private_worker_pool_id  = try(data.terraform_remote_state.bootstrap.outputs.cloud_build_private_worker_pool_id, "")
  cloud_builder_artifact_repo         = try(data.terraform_remote_state.bootstrap.outputs.cloud_builder_artifact_repo, "")
  enable_cloudbuild_deploy            = local.cloud_builder_artifact_repo != ""
  environment_kms_key_ring            = data.terraform_remote_state.environments_env.outputs.key_rings
  app_infra_pipeline_service_accounts = data.terraform_remote_state.business_unit_shared.outputs.terraform_service_accounts
  infra_sa_map                        = try(local.app_infra_pipeline_service_accounts, {})
}

data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/bootstrap/state"
  }
}

data "terraform_remote_state" "org" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/org/state"
  }
}

data "terraform_remote_state" "environments_env" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/environments/${var.env}"
  }
}

data "terraform_remote_state" "business_unit_shared" {
  backend = "gcs"

  config = {
    bucket = local.projects_backend_bucket
    prefix = "terraform/projects/${var.business_unit}/shared"
  }
}
