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

variable "project_id" {
  description = "Project ID of the project in which Cloud DNS configurations will be made."
  type        = string
}

variable "private_service_connect_ip" {
  description = "Google Private Service Connect IP Address."
  type        = string
}

variable "private_visibility_config_networks" {
  description = "List of VPC self links that can see this zone."
  type        = list(string)
  default     = []
}

variable "zone_names" {
  description = <<EOT
  Defines the names of each zone created in the module:
  - "notebooks_googleusercontent_zone" corresponds to "notebooks.googleusercontent.com." domain zone name.
  - "kernels_googleusercontent_zone" corresponds to "kernels.googleusercontent.com." domain zone name.
  - "notebooks_cloudgoogle_zone" corresponds to "notebooks.cloud.google.com." domain zone name.
  EOT
  type = object({
    notebooks_googleusercontent_zone = string
    kernels_googleusercontent_zone   = string
    notebooks_cloudgoogle_zone       = string
  })
}
