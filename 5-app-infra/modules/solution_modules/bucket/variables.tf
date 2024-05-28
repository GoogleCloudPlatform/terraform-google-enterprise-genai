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
  type        = string
  description = "name of bucket"
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

variable "dual_region_locations" {
  type        = list(string)
  default     = []
  description = "dual region description"
  validation {
    condition     = length(var.dual_region_locations) == 0 || length(var.dual_region_locations) == 2
    error_message = "Exactly 0 or 2 regions expected."
  }
}

variable "force_destroy" {
  type        = bool
  description = "(Optional, Default: true) When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
  default     = true
}

variable "versioning_enabled" {
  type        = bool
  description = "Whether to enable versioning or not"
  default     = true
}

variable "lifecycle_rules" {
  type = set(object({
    # Object with keys:
    # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.
    # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.
    action = map(string)

    # Object with keys:
    # - age - (Optional) Minimum age of an object in days to satisfy this condition.
    # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.
    # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".
    # - matches_storage_class - (Optional) Comma delimited string for storage class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL.
    # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.
    # - custom_time_before - (Optional) A date in the RFC 3339 format YYYY-MM-DD. This condition is satisfied when the customTime metadata for the object is set to an earlier date than the date used in this lifecycle condition.
    # - days_since_custom_time - (Optional) The number of days from the Custom-Time metadata attribute after which this condition becomes true.
    # - days_since_noncurrent_time - (Optional) Relevant only for versioned objects. Number of days elapsed since the noncurrent timestamp of an object.
    # - noncurrent_time_before - (Optional) Relevant only for versioned objects. The date in RFC 3339 (e.g. 2017-06-13) when the object became nonconcurrent.
    condition = map(string)
  }))
  description = "List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches_storage_class should be a comma delimited string."
  default = [
    {
      #Deletion Rules
      #Control ID: GCS-CO-6.5
      #NIST 800-53: SC-12
      #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age                   = "30"
        matches_storage_class = "REGIONAL"
      }
    },
    {
      #Deletion Rules
      #Control ID: GCS-CO-6.6
      #NIST 800-53: SC-12
      #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3
      action = {
        type = "Delete"
      }
      condition = {
        with_state = "ARCHIVED"
      }
    }
  ]
}

variable "retention_policy" {
  type        = any
  default     = {}
  description = "Map of retention policy values. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket#retention_policy"
}

variable "object_folder_temporary_hold" {
  type        = bool
  default     = false
  description = "Set root folder temporary hold according to security control GCS-CO-6.16, toggle off to allow for object deletion."
}

#Labeling Tag
#Control ID: GCS-CO-6.4
#NIST 800-53: SC-12
#CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

variable "labels" {
  description = "Labels to be attached to the buckets"
  type        = map(string)
  default = {
    #Labelling tag
    #Control ID: GCS-CO-6.4
    #NIST 800-53: SC-12
    #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

    label = "samplelabel"

    #Owner Tag
    #Control ID: GCS-CO-6.8
    #NIST 800-53: SC-12
    #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

    owner = "testowner"

    #Classification Tag
    #Control ID: GCS-CO-6.18
    #NIST 800-53: SC-12
    #CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

    classification = "dataclassification"
  }
}

variable "add_random_suffix" {
  description = "whether to add a random suffix to the bucket name"
  type        = bool
  default     = false
}

variable "uniform_bucket_level_access" {
  description = "Whether to have uniform access levels or not"
  type        = bool
  default     = true
}

variable "storage_class" {
  type        = string
  description = "Storage class to create the bucket"
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class can be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "requester_pays" {
  description = "Enables Requester Pays on a storage bucket."
  type        = bool
  default     = false
}

variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for GCS Bucket"
  type        = string
  default     = "bkt"
}

variable "project_id" {
  type        = string
  description = "Optional Project ID."
  default     = null
}
