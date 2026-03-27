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

variable "key_rings" {
  description = "Keyrings to attach project key to."
  type        = list(string)
}

variable "project_name" {
  description = "Project Name."
  type        = string
}

variable "key_rotation_period" {
  description = "Rotation period in seconds to be used for KMS Key."
  type        = string
  default     = "7776000s"
}

variable "prevent_destroy" {
  description = "Prevent Key destruction."
  type        = bool
}
