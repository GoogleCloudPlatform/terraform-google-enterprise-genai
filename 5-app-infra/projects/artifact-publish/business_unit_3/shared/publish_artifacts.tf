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

module "artifact_publish" {
  source = "../../modules/publish_artifacts"

  environment = local.environment
  description = "Publish Artifacts for ML Projects"
  project_id  = local.common_artifacts_project_id
  name        = local.artifacts_repo_name
  format      = "DOCKER"
  region      = var.instance_region
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
