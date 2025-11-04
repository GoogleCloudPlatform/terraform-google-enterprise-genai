/**
 * Copyright 2024 Google LLC
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

module "ml_dns_vertex_ai" {
  source = "../ml_dns_notebooks"

  project_id                         = local.restricted_project_id
  private_service_connect_ip         = var.restricted_private_service_connect_ip
  private_visibility_config_networks = [module.restricted_shared_vpc.network_self_link]
  zone_names = {
    kernels_googleusercontent_zone   = "dz-${var.environment_code}-shared-restricted-kernels-googleusercontent"
    notebooks_googleusercontent_zone = "dz-${var.environment_code}-shared-restricted-notebooks-googleusercontent"
    notebooks_cloudgoogle_zone       = "dz-${var.environment_code}-shared-restricted-notebooks"
  }
}
