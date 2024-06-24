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
  description = "Project ID."
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

variable "secret_names" {
  type        = list(string)
  description = "Names of the secrets to be created."
}

variable "kms_keyring" {
  type        = string
  description = <<EOF
The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.
This value can be obtained by running "gcloud kms keyrings list --project=KMS_PROJECT_ID --location=REGION."
EOF
}
