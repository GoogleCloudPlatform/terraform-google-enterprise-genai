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

variable "instance_region" {
  description = "The region where notebook instance will be created. A subnetwork must exists in the instance region."
  type        = string
}

variable "remote_state_bucket" {
  description = "Backend bucket to load remote state information from previous steps."
  type        = string
}

variable "github_app_installation_id" {
  description = "The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build"
  type        = number

}
variable "github_remote_uri" {
  description = "The remote uri of your github repository"
  type        = string
}

variable "seed_state_bucket" {
  description = "Remote state bucket from 0-bootstrap"
  type        = string
}

variable "repository_id" {
  description = "Common artifacts repository id"
  type = string
  default = "c-publish-artifacts"
}
