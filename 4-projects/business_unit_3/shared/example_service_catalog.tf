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

locals {
  service_catalog_tf_sa_roles = [
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountAdmin",
    "roles/cloudbuild.connectionAdmin",
  ]
}
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
    "logging.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudkms.googleapis.com",
  ]
  # Metadata
  project_suffix    = "service-catalog"
  application_name  = "app-infra-ml"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "bu3"
}

resource "google_kms_crypto_key" "sc_key" {
  for_each        = toset(local.shared_kms_key_ring)
  name            = module.app_service_catalog_project[0].project_name
  key_ring        = each.key
  rotation_period = var.key_rotation_period
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_kms_crypto_key_iam_member" "sc_key" {
  for_each      = google_kms_crypto_key.sc_key
  crypto_key_id = each.value.id
  role          = "roles/cloudkms.admin"
  member        = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-service-catalog"]}"
}

resource "google_project_iam_member" "service_catalog_tf_sa_roles" {
  for_each = toset(local.service_catalog_tf_sa_roles)
  project  = module.app_service_catalog_project[0].project_id
  role     = each.key
  member   = "serviceAccount:${module.infra_pipelines[0].terraform_service_accounts["bu3-service-catalog"]}"
}


# resource "random_string" "bucket_name" {
#   length  = 4
#   upper   = false
#   numeric = true
#   lower   = true
#   special = false
# }

# module "service_catalog_gcs_bucket" {
#   source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
#   version = "~> 4.0"

#   location   = local.location_gcs
#   name       = "${var.gcs_bucket_prefix}-${module.app_service_catalog_project[0].project_id}-${lower(local.location_gcs)}-svc-ctlg-${random_string.bucket_name.result}"
#   project_id = module.app_service_catalog_project[0].project_id

#   depends_on = [module.app_service_catalog_project]
# }


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
