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
  application_name = "app-pipelines"
  business_code    = local.business_code
}
