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

module "app_service_catalog_project" {
  source = "../../modules/single_project"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id          = local.org_id
  billing_account = local.billing_account
  folder_id       = local.common_folder_name
  environment     = "common"
  project_budget  = var.project_budget
  project_prefix  = local.project_prefix
  activate_apis = [
    "admin.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "datacatalog.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "notebooks.googleapis.com",
    "storage.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
  # Metadata
  project_suffix    = "service-catalog"
  application_name  = "app-infra-ml"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "bu3"
}

resource "random_string" "bucket_name" {
  length  = 4
  upper   = false
  numeric = true
  lower   = true
  special = false
}

module "service_catalog_gcs_bucket" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 4.0"

  location   = local.location_gcs
  name       = "${var.gcs_bucket_prefix}-${module.app_service_catalog_project[0].project_id}-${lower(local.location_gcs)}-svc-ctlg-${random_string.bucket_name.result}"
  project_id = module.app_service_catalog_project[0].project_id

  depends_on = [module.app_service_catalog_project]
}


/**
 * When Jenkins CICD is used for deployment this resource
 * is created to terraform validation works.
 * Without this resource, this module creates zero resources
 * and it breaks terraform validation throwing the error below:
 * ERROR: [Terraform plan json does not contain resource_changes key]
 */
resource "null_resource" "jenkins_cicd_service_catalog" {
  count = !local.enable_cloudbuild_deploy ? 1 : 0
}
