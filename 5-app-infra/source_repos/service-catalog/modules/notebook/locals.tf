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

locals {
  name_var = format("%s-%s", data.google_project.project.labels.env_code, var.name)

  region              = substr(var.location, 0, length(var.location) - 2)
  notebooks_node_use4 = "172.16.8.0/22"
  notebooks_node_usc1 = "172.17.8.0/22"

  # notebooks specific
  notebooks_master_use4 = "192.168.0.0/28"
  notebooks_master_usc1 = "192.168.1.0/28"

  network_name = local.region == "us-central1" ? "notebooks-vpc-usc1" : "notebooks-vpc-use4"
  subnetwork   = local.region == "us-central1" ? "notebooks-primary-usc1" : "notebooks-primary-use4"

  keyring_name = "sample-keyring"
}
