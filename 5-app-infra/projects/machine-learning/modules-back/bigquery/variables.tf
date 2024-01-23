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
  type        = string
  description = "Optional Project ID."
  default     = null
}

variable "dataset_id" {
  description = "A unique ID for this dataset, without the project name. The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_). The maximum length is 1,024 characters."
  type        = string
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

variable "friendly_name" {
  description = "A descriptive name for the dataset"
  type        = string
  default     = ""
}

variable "description" {
  description = "A user-friendly description of the dataset"
  type        = string
  default     = ""
}

variable "default_partition_expiration_ms" {
  description = "The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value."
  type        = number
  default     = null
}

variable "default_table_expiration_ms" {
  description = "The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property."
  type        = number
  default     = null
}

variable "delete_contents_on_destroy" {
  description = "If true, delete all the tables in the dataset when destroying the dataset; otherwise, destroying the dataset does not affect the tables in the dataset. If you try to delete a dataset that contains tables, and you set delete_contents_on_destroy to false when you created the dataset, the request will fail. Always use this flag with caution. A missing value is treated as false."
  type        = bool
  default     = false
}
