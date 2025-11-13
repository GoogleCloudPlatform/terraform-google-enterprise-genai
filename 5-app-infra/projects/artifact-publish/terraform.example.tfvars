/**
<<<<<<<< HEAD:0-bootstrap/modules/gitlab-oidc/versions.tf
 * Copyright 2023 Google LLC
========
 * Copyright 2025 Google LLC
>>>>>>>> main:5-app-infra/projects/artifact-publish/terraform.example.tfvars
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

<<<<<<<< HEAD:0-bootstrap/modules/gitlab-oidc/versions.tf
terraform {
  required_version = ">= 0.13"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 3.64, < 7"
    }
  }

}
========
instance_region = "us-central1" // should be one of the regions used to create network on step 3-networks

remote_state_bucket = "REMOTE_STATE_BUCKET"
>>>>>>>> main:5-app-infra/projects/artifact-publish/terraform.example.tfvars
