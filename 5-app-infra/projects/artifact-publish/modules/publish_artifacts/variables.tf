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

variable "region" {
  description = "Location of the repository."
  type        = string
}
variable "name" {
  description = "Name of the repository."
  type        = string
}

variable "description" {
  description = "Description of the repository."
  type        = string
}

variable "format" {
  description = "Format of the repository."
  type        = string
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
}

variable "environment" {
  type        = string
  description = "development | staging | production | commmon"
  validation {
    condition     = contains(["development", "staging", "production", "common"], var.environment)
    error_message = "Environment must be one of [development, staging, production]."
  }
}

variable "project_id" {
  description = "Project ID"
}
variable "cloudbuild_repo_id" {
  description = "CloudBuild repository id"
  type        = string
}

variable "github_remote_uri" {
  description = "The remote uri of your github repository"
  type        = string
}

variable "secret_version_name" {
  description = "Secret Version Name of key"
  type        = string
}
