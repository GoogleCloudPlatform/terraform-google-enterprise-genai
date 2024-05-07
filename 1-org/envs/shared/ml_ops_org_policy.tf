/**
 * Copyright 2023 Google LLC
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

module "ml_organization_policies" {
  source = "../../modules/ml-org-policies"

  org_id    = local.organization_id
  folder_id = local.folder_id

  allowed_locations = [
    "us-locations"
  ]

  allowed_vertex_vpc_networks = {
    parent_type = "project"
    parent_ids  = [for instance in module.base_restricted_environment_network : instance.restricted_shared_vpc_project_id],
  }

  allowed_vertex_images = [
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cu113-notebooks",
    "ainotebooks-vm/deeplearning-platform-release/image-family/common-cpu-notebooks",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py37",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu110.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-cpu.2-12.py310",
    "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-gpu.2-12.py310"
  ]

  restricted_services = [
    "alloydb.googleapis.com"
  ]

  allowed_integrations = [
    "github.com",
    "source.developers.google.com"
  ]

  restricted_tls_versions = [
    "TLS_VERSION_1",
    "TLS_VERSION_1_1"
  ]

  restricted_non_cmek_services = [
    "bigquery.googleapis.com",
    "aiplatform.googleapis.com"
  ]

  allowed_vertex_access_modes = [
    "single-user",
    "service-account"
  ]
}
