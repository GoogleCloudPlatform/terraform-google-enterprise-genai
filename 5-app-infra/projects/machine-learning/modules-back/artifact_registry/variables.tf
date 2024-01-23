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

variable "name" {
  description = "Name of the repository."
  type        = string
}

variable "description" {
  description = "Description of the repository."
  type        = string
  default     = ""
}

variable "format" {
  description = "Format of the repository."
  type        = string
  default     = "DOCKER"
}

variable "region" {
  type        = string
  description = "The resource region, one of [us-central1, us-east4]."
  default     = "us-central1"
  validation {
    condition     = contains(["us-central1", "us-east4"], var.region)
    error_message = "Region must be one of [us-central1, us-east4]."
  }
}

variable "cleanup_policy_dry_run" {
  description = "Whether to perform a dry run of the cleanup policy."
  type        = bool
  default     = false
}

variable "cleanup_policies" {
  description = "List of cleanup policies."
  type = list(object({
    id     = string
    action = optional(string)
    condition = optional(list(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
    })))
    most_recent_versions = optional(list(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    })))
  }))
  default = [
    {
      id     = "delete-prerelease"
      action = "DELETE"
      condition = [
        {
          tag_state    = "TAGGED"
          tag_prefixes = ["alpha", "v0"]
          older_than   = "2592000s"
        }
      ]
    }
  ]
}

variable "project_id" {
  type        = string
  description = "Optional Project ID."
  default     = null
}
