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
  description = "name of the Composer environment"
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

variable "labels" {
  type        = map(string)
  description = "The resource labels (a map of key/value pairs) to be applied to the Cloud Composer."
  default     = {}
}

variable "maintenance_window" {
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

################################################
#             software_config                  #
################################################
variable "airflow_config_overrides" {
  type        = map(string)
  description = "Airflow configuration properties to override. Property keys contain the section and property names, separated by a hyphen, for example \"core-dags_are_paused_at_creation\"."
  default     = {}
}

variable "env_variables" {
  type        = map(any)
  description = "Additional environment variables to provide to the Apache Airflow scheduler, worker, and webserver processes. Environment variable names must match the regular expression [a-zA-Z_][a-zA-Z0-9_]*. They cannot specify Apache Airflow software configuration overrides (they cannot match the regular expression AIRFLOW__[A-Z0-9_]+__[A-Z0-9_]+), and they cannot match any of the following reserved names: [AIRFLOW_HOME,C_FORCE_ROOT,CONTAINER_NAME,DAGS_FOLDER,GCP_PROJECT,GCS_BUCKET,GKE_CLUSTER_NAME,SQL_DATABASE,SQL_INSTANCE,SQL_PASSWORD,SQL_PROJECT,SQL_REGION,SQL_USER]"
  default     = {}
}

variable "image_version" {
  type        = string
  description = "The version of the aiflow running in the cloud composer environment."
  default     = "composer-2.5.2-airflow-2.6.3"
  validation {
    condition     = can(regex("^composer-([2-9]|[1-9][0-9]+)\\..*$", var.image_version))
    error_message = "The airflow_image_version must be GCP Composer version 2 or higher (e.g., composer-2.x.x-airflow-x.x.x)."
  }
}

variable "pypi_packages" {
  type        = map(string)
  description = " Custom Python Package Index (PyPI) packages to be installed in the environment. Keys refer to the lowercase package name (e.g. \"numpy\")."
  default     = {}
}

variable "python_version" {
  description = "The default version of Python used to run the Airflow scheduler, worker, and webserver processes."
  type        = string
  default     = "3"
}

variable "web_server_allowed_ip_ranges" {
  description = "The network-level access control policy for the Airflow web server. If unspecified, no network-level access restrictions will be applied."
  default     = null
  type = list(object({
    value       = string
    description = string
  }))
}

variable "github_remote_uri" {
  description = "Url of your github repo"
  type        = string
}

variable "github_api_token" {
  description = "API Token from your github repository"
  type        = string
  sensitive   = true
}

variable "github_name_prefix" {
  description = "A name for your github connection to cloubuild"
  type        = string
  default     = "github-modules"
}

variable "github_app_installation_id" {
  description = "The app installation ID that was created when installing Google Cloud Build in Github: https://github.com/apps/google-cloud-build"
  type        = number

}

variable "service_account_prefix" {
  description = "Name prefix to use for service accounts."
  type        = string
  default     = "sa"
}

variable "project_id" {
  description = "Optional project ID where Cloud Composer Environment is created."
  type        = string
  default     = null
}
