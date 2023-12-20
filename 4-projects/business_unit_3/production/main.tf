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
  source              = "../../modules/env_folders"
  business_code       = local.business_code
  remote_state_bucket = var.remote_state_bucket
  env                 = var.env
}
# module "env" {
#   source = "../../modules/base_env"

#   env                          = "production"
#   business_code                = "bu3"
#   business_unit                = "business_unit_3"
#   remote_state_bucket          = var.remote_state_bucket
#   location_kms                 = var.location_kms
#   location_gcs                 = var.location_gcs
#   tfc_org_name                 = var.tfc_org_name
#   peering_module_depends_on    = var.peering_module_depends_on
#   peering_iap_fw_rules_enabled = true
#   subnet_region                = var.instance_region
#   subnet_ip_range              = "10.5.192.0/21"
# }

module "composer_cloudbuild_project" {
  source              = "../../modules/app_pipelines"
  count               = local.enable_cloudbuild_deploy ? 1 : 0
  repo_name           = local.repo_name
  env                 = var.env
  default_region      = var.default_region
  remote_state_bucket = var.remote_state_bucket
  folder_id           = module.bu_folder.business_unit_folder
  activate_apis = [
    "logging.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "composer.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
  #Metadata
  project_suffix   = "cmpsr-pipeln"
  application_name = "compsoer-pipeline"
  business_code    = local.business_code
}
module "ml_env" {
  source = "../../modules/ml_env"

  env                  = var.env
  business_code        = local.business_code
  business_unit        = local.buiness_unit
  remote_state_bucket  = var.remote_state_bucket
  location_gcs         = var.location_gcs
  tfc_org_name         = var.tfc_org_name
  business_unit_folder = module.bu_folder.business_unit_folder

}
