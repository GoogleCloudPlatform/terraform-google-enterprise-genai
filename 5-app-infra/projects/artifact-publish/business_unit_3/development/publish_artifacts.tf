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


module "artifact_pipeline" {
  source                     = "../../modules/pipeline_base"
  environment                = local.environment
  project_id                 = local.common_artifacts_project_id
  name                       = "publish-artifacts"
  github_app_installation_id = var.github_app_installation_id
  github_name_prefix         = "github-cloudbuild"
  github_api_token           = var.github_api_token
  github_remote_uri          = var.github_remote_uri
  region                     = var.instance_region
}
module "artifact_publish" {
  source = "../../modules/publish_artifacts"

  environment = local.environment
  description = "Publish Artifacts for ML Projects"
  project_id  = local.common_artifacts_project_id
  name        = "publish-artifacts"
  format      = "DOCKER"
  # github_app_installation_id = var.github_app_installation_id
  # github_api_token           = var.github_api_token
  # github_remote_uri          = var.github_remote_uri
  cloudbuild_repo_id = module.artifact_pipeline.cloudbuild_v2_repo_id
  region             = var.instance_region
  # remote_state_bucket = var.remote_state_bucket
  cleanup_policies = [{
    id     = "keep-tagged-release"
    action = "KEEP"
    condition = [
      {
        tag_state             = "TAGGED",
        tag_prefixes          = ["release"],
        package_name_prefixes = ["webapp", "mobile"]
      }
    ]
  }]
}
