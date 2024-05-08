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

variable "keyring_name" {
  description = "Name to be used for Cloud Key Management Service (KMS) Keyring"
  type        = string
  default     = "sample-keyring"
}

variable "keyring_regions" {
  description = "Regions to create keyrings in"
  type        = list(string)
  default = [
    "us-central1",
    "us-east4"
  ]
}

variable "keyring_admins" {
  description = "IAM members that shall be granted admin on the keyring. Format need to specify member type, i.e. 'serviceAccount:', 'user:', 'group:'"
  type        = list(string)
}

variable "project_id" {
  description = "Project where the resource will be created"
  type        = string
}

variable "keys" {
  description = "Key names."
  type        = list(string)
  default     = []
}

variable "kms_prevent_destroy" {
  description = "Wheter to prevent keyring and keys destruction. Must be set to false if the user wants to disable accidental terraform deletions protection."
  type        = bool
  default     = true
}
