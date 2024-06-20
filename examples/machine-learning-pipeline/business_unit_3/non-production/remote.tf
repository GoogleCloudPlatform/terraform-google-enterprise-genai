/**
 * Copyright 2021 Google LLC
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
  machine_learning_project_id   = data.terraform_remote_state.projects_env.outputs.machine_learning_project_id
  machine_learning_kms_keys     = data.terraform_remote_state.projects_env.outputs.machine_learning_kms_keys
  service_catalog_repo_name     = data.terraform_remote_state.projects_shared.outputs.service_catalog_repo_name
  service_catalog_project_id    = data.terraform_remote_state.projects_shared.outputs.service_catalog_project_id
  non_production_project_number = data.terraform_remote_state.projects_nonproduction.outputs.machine_learning_project_number
  non_production_project_id     = data.terraform_remote_state.projects_nonproduction.outputs.machine_learning_project_id
  production_project_number     = data.terraform_remote_state.projects_production.outputs.machine_learning_project_number
  production_project_id         = data.terraform_remote_state.projects_production.outputs.machine_learning_project_id
}

data "terraform_remote_state" "projects_env" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/projects/${local.business_unit}/${local.env}"
  }
}

data "terraform_remote_state" "projects_shared" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/projects/${local.business_unit}/shared"
  }
}

data "terraform_remote_state" "projects_production" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/projects/${local.business_unit}/production"
  }
}

data "terraform_remote_state" "projects_nonproduction" {
  backend = "gcs"

  config = {
    bucket = var.remote_state_bucket
    prefix = "terraform/projects/${local.business_unit}/non-production"
  }
}