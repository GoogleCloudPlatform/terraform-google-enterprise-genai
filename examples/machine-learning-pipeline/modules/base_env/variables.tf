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

########################
#     Global Inputs    #
########################

variable "env" {
  description = "Environment name. (ex. production)"
  type        = string
}

variable "environment_code" {
  description = "Environment code. (ex. p for production)"
  type        = string
}

variable "business_code" {
  description = "Business unit code (ie. bu3)"
  type        = string

}

variable "project_id" {
  description = "Environments Machine Learning Project ID"
  type        = string
}

variable "non_production_project_number" {
  description = "Non-production Machine Learning Project Number"
  type        = string
}

variable "non_production_project_id" {
  description = "Non-production Machine Learning Project ID"
  type        = string
}

variable "production_project_number" {
  description = "Production Machine Learning Project Number"
  type        = string
}

variable "production_project_id" {
  description = "Production Machine Learning Project ID"
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

variable "kms_keys" {
  description = "Project's KMS Crypto keys."
  type        = map(any)
}

variable "gcs_bucket_prefix" {
  description = "Name prefix to be used for GCS Bucket"
  type        = string
  default     = "bkt"
}

variable "service_account_prefix" {
  description = "Name prefix to use for service accounts."
  type        = string
  default     = "sa"
}

########################
#      Composer        #
########################

variable "composer_enabled" {
  description = "Enable Composer (defualt to false)"
  type        = bool
  default     = false
}
variable "composer_name" {
  description = "Name of Composer environment"
  type        = string
  default     = null
}

variable "composer_github_remote_uri" {
  description = "Url of your github repo"
  type        = string
  default     = null
}

variable "composer_github_app_installation_id" {
  description = "The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build"
  type        = number
  default     = null
}

variable "composer_labels" {
  type        = map(string)
  description = "The resource labels (a map of key/value pairs) to be applied to the Cloud Composer."
  default     = {}
}

variable "composer_maintenance_window" {
  type = object({
    start_time = string
    end_time   = string
    recurrence = string
  })

  description = "The configuration settings for Cloud Composer maintenance window."

  # Set Start time, Timezone, Days, and Length, so that combined time for the
  # specified schedule is at least 12 hours in a 7-day rolling window. For example,
  # a period of 4 hours every Monday, Wednesday, and Friday provides the required amount of time.

  # 12-hour maintenance window between 01:00 and 13:00 (UTC) on Sundays
  default = {
    start_time = "2021-01-01T01:00:00Z"
    end_time   = "2021-01-01T13:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SU"
  }
}

variable "composer_airflow_config_overrides" {
  type        = map(string)
  description = "Airflow configuration properties to override. Property keys contain the section and property names, separated by a hyphen, for example \"core-dags_are_paused_at_creation\"."
  default     = {}
}

variable "composer_env_variables" {
  type        = map(any)
  description = "Additional environment variables to provide to the Apache Airflow scheduler, worker, and webserver processes. Environment variable names must match the regular expression [a-zA-Z_][a-zA-Z0-9_]*. They cannot specify Apache Airflow software configuration overrides (they cannot match the regular expression AIRFLOW__[A-Z0-9_]+__[A-Z0-9_]+), and they cannot match any of the following reserved names: [AIRFLOW_HOME,C_FORCE_ROOT,CONTAINER_NAME,DAGS_FOLDER,GCP_PROJECT,GCS_BUCKET,GKE_CLUSTER_NAME,SQL_DATABASE,SQL_INSTANCE,SQL_PASSWORD,SQL_PROJECT,SQL_REGION,SQL_USER]"
  default     = {}
}

variable "composer_image_version" {
  type        = string
  description = "The version of the aiflow running in the cloud composer environment."
  default     = "composer-2.5.2-airflow-2.6.3"
  validation {
    condition     = can(regex("^composer-([2-9]|[1-9][0-9]+)\\..*$", var.composer_image_version))
    error_message = "The airflow_image_version must be GCP Composer version 2 or higher (e.g., composer-2.x.x-airflow-x.x.x)."
  }
}

variable "composer_pypi_packages" {
  type        = map(string)
  description = " Custom Python Package Index (PyPI) packages to be installed in the environment. Keys refer to the lowercase package name (e.g. \"numpy\")."
  default     = {}
}

variable "composer_python_version" {
  description = "The default version of Python used to run the Airflow scheduler, worker, and webserver processes."
  type        = string
  default     = "3"
}

variable "composer_web_server_allowed_ip_ranges" {
  description = "The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions will be applied."
  default     = null
  type = list(object({
    value       = string
    description = string
  }))
}

variable "composer_github_secret_name" {
  description = "Name of the github secret to extract github token info"
  type        = string
  default     = "github-api-token"
}

########################
#      Big Query       #
########################

variable "big_query_dataset_id" {
  description = "A unique ID for this dataset, without the project name. The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_). The maximum length is 1,024 characters."
  type        = string
  default     = null
}

variable "big_query_friendly_name" {
  description = "A descriptive name for the dataset"
  type        = string
  default     = ""
}

variable "big_query_description" {
  description = "A user-friendly description of the dataset"
  type        = string
  default     = ""
}

variable "big_query_default_partition_expiration_ms" {
  description = "The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value."
  type        = number
  default     = null
}

variable "big_query_default_table_expiration_ms" {
  description = "The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property."
  type        = number
  default     = null
}

variable "big_query_delete_contents_on_destroy" {
  description = "If true, delete all the tables in the dataset when destroying the dataset; otherwise, destroying the dataset does not affect the tables in the dataset. If you try to delete a dataset that contains tables, and you set delete_contents_on_destroy to false when you created the dataset, the request will fail. Always use this flag with caution. A missing value is treated as false."
  type        = bool
  default     = false
}

########################
#      Metadata        #
########################

variable "metadata_name" {
  type        = string
  description = "The name of the metadata store instance"
  default     = null
}

########################
#       Bucket         #
########################

variable "bucket_name" {
  type        = string
  description = "name of bucket"
  default     = null
}

variable "bucket_dual_region_locations" {
  type        = list(string)
  default     = []
  description = "dual region description"
  validation {
    condition     = length(var.bucket_dual_region_locations) == 0 || length(var.bucket_dual_region_locations) == 2
    error_message = "Exactly 0 or 2 regions expected."
  }
}

variable "bucket_force_destroy" {
  type        = bool
  description = "(Optional, Default: true) When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
  default     = true
}

variable "bucket_versioning_enabled" {
  type        = bool
  description = "Whether to enable versioning or not"
  default     = true
}

variable "bucket_lifecycle_rules" {
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

variable "bucket_retention_policy" {
  type        = any
  default     = {}
  description = "Map of retention policy values. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket#retention_policy"
}

variable "bucket_object_folder_temporary_hold" {
  type        = bool
  default     = false
  description = "Set root folder temporary hold according to security control GCS-CO-6.16, toggle off to allow for object deletion."
}

#Labeling Tag
#Control ID: GCS-CO-6.4
#NIST 800-53: SC-12
#CRI Profile: PR.IP-2.1 PR.IP-2.2 PR.IP-2.3

variable "bucket_labels" {
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

variable "bucket_add_random_suffix" {
  description = "whether to add a random suffix to the bucket name"
  type        = bool
  default     = false
}

variable "bucket_uniform_bucket_level_access" {
  description = "Whether to have uniform access levels or not"
  type        = bool
  default     = true
}

variable "bucket_storage_class" {
  type        = string
  description = "Storage class to create the bucket"
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "MULTI_REGIONAL", "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"], var.bucket_storage_class)
    error_message = "Storage class can be one of STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "bucket_requester_pays" {
  description = "Enables Requester Pays on a storage bucket."
  type        = bool
  default     = false
}


########################
#      TensorBoard     #
########################

variable "tensorboard_name" {
  type        = string
  description = "The name of the metadata store instance"
  default     = null
}
