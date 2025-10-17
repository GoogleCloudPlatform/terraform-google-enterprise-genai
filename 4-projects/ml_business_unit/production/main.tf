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

module "bu_folder" {
  source                     = "../../modules/env_folders"
  business_code              = local.business_code
  remote_state_bucket        = var.remote_state_bucket
  env                        = var.env
  folder_deletion_protection = var.folder_deletion_protection

}

module "ml_env" {
  source = "../../modules/ml_env"

  env                     = var.env
  business_code           = local.business_code
  business_unit           = local.business_unit
  remote_state_bucket     = var.remote_state_bucket
  location_gcs            = var.location_gcs
  tfc_org_name            = var.tfc_org_name
  business_unit_folder    = module.bu_folder.business_unit_folder
  project_deletion_policy = var.project_deletion_policy

}
