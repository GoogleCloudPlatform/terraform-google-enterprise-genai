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

module "app_infra_service_catalog_project" {
  source = "../../modules/single_project"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id          = local.org_id
  billing_account = local.billing_account
  folder_id       = local.common_folder_name
  environment     = "common"
  project_budget  = var.project_budget
  project_prefix  = local.project_prefix
  activate_apis = [
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "billingbudgets.googleapis.com",
  ]
  # Metadata
  project_suffix    = "artifacts"
  application_name  = "app-infra-ml"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "bu3"
}

/**
 * When Jenkins CICD is used for deployment this resource
 * is created to terraform validation works.
 * Without this resource, this module creates zero resources
 * and it breaks terraform validation throwing the error below:
 * ERROR: [Terraform plan json does not contain resource_changes key]
 */
resource "null_resource" "jenkins_cicd_artifacts" {
  count = !local.enable_cloudbuild_deploy ? 1 : 0
}
