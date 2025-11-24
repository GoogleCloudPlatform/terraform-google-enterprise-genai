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
  repo_names = [
    "ml-artifact-publish",
    "ml-service-catalog",
    "ml-machine-learning",
  ]
}

module "app_infra_cloudbuild_project" {
  source = "../../modules/single_project"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id              = local.org_id
  billing_account     = local.billing_account
  folder_id           = local.common_folder_name
  environment         = "common"
  project_budget      = var.project_budget
  project_prefix      = local.project_prefix
  key_rings           = local.shared_kms_key_ring
  remote_state_bucket = var.remote_state_bucket

  activate_apis = [
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
  ]

  # Metadata
  project_suffix    = "infra-pipeline"
  application_name  = "app-infra-pipelines"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = "ml"
}

module "infra_pipelines" {
  source = "../../modules/infra_pipelines"
  count  = local.enable_cloudbuild_deploy ? 1 : 0

  org_id                      = local.org_id
  cloudbuild_project_id       = module.app_infra_cloudbuild_project[0].project_id
  cloud_builder_artifact_repo = local.cloud_builder_artifact_repo
  remote_tfstate_bucket       = local.projects_remote_bucket_tfstate
  billing_account             = local.billing_account
  default_region              = var.default_region
  app_infra_repos             = local.repo_names
  private_worker_pool_id      = local.cloud_build_private_worker_pool_id
}

resource "google_kms_key_ring_iam_member" "key_ring" {
  for_each = local.enable_cloudbuild_deploy ? { for k in flatten([for kms in local.shared_kms_key_ring : [for name, email in module.infra_pipelines[0].terraform_service_accounts : { key = "${kms}--${name}", kms = kms, email = email }]]) : k.key => k } : {}

  key_ring_id = each.value.kms
  role        = "roles/cloudkms.admin"
  member      = "serviceAccount:${each.value.email}"
}

/**
 * When Jenkins CICD is used for deployment this resource
 * is created to terraform validation works.
 * Without this resource, this module creates zero resources
 * and it breaks terraform validation throwing the error below:
 * ERROR: [Terraform plan json does not contain resource_changes key]
 */
resource "null_resource" "jenkins_cicd" {
  count = !local.enable_cloudbuild_deploy ? 1 : 0
}
