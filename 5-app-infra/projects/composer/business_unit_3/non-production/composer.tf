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


module "composer_pipeline" {
  source = "../../modules/pipeline_base"

  environment                = local.environment
  project_id                 = local.composer_project_id
  name                       = "composer"
  github_app_installation_id = var.github_app_installation_id
  github_name_prefix         = "github-composer-cloudbuild"
  github_api_token           = var.github_api_token
  github_remote_uri          = var.github_remote_uri
  region                     = var.instance_region
}

module "composer" {
  source = "../../modules/composer"

  name                = "foundation-isolated-composer"
  environment         = local.environment
  region              = var.instance_region
  project_id          = local.composer_project_id
  cloudbuild_repo_id  = module.composer_pipeline.cloudbuild_v2_repo_id
  secret_version_name = module.composer_pipeline.github_secret_version_name
  github_remote_uri   = var.github_remote_uri
  airflow_config_overrides = {
    core-dags_are_paused_at_creation = "true"
  }
  image_version = "composer-2.5.2-airflow-2.6.3"
}
