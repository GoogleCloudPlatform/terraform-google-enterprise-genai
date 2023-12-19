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


module "service_catalog_pipeline" {
  source = "../../modules/pipeline_base"

  environment                = local.environment
  project_id                 = local.service_catalog_project_id
  name                       = "service-catalog"
  github_app_installation_id = var.github_app_installation_id
  github_name_prefix         = "github-sc-cloudbuild"
  github_api_token           = var.github_api_token
  github_remote_uri          = var.github_remote_uri
  region                     = var.instance_region
}

module "service_catalog" {
  source = "../../modules/svc_ctlg"

  environment         = local.environment
  project_id          = local.service_catalog_project_id
  region              = var.instance_region
  cloudbuild_repo_id  = module.service_catalog_pipeline.cloudbuild_v2_repo_id
  secret_version_name = module.service_catalog_pipeline.github_secret_version_name
  github_remote_uri   = var.github_remote_uri
}
