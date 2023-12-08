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

module "machine_learning_project" {
  source = "../single_project"

  org_id          = local.org_id
  billing_account = local.billing_account
  folder_id       = google_folder.env_business_unit.name
  environment     = var.env
  project_budget  = var.project_budget
  project_prefix  = local.project_prefix

  // Enabling Cloud Build Deploy to use Service Accounts during the build and give permissions to the SA.
  // The permissions will be the ones necessary for the deployment of the step 5-app-infra
  enable_cloudbuild_deploy = local.enable_cloudbuild_deploy

  // A map of Service Accounts to use on the infra pipeline (Cloud Build)
  // Where the key is the repository name ("${var.business_code}-example-app")
  app_infra_pipeline_service_accounts = local.app_infra_pipeline_service_accounts

  // Map for the roles where the key is the repository name ("${var.business_code}-example-app")
  // and the value is the list of roles that this SA need to deploy step 5-app-infra
  sa_roles = {
    "${var.business_code}-example-app" = [
      "roles/compute.instanceAdmin.v1",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountUser",
    ]
  }

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "deploymentmanager.googleapis.com",
    "logging.googleapis.com",
    "notebooks.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
  ]


  # Metadata
  project_suffix    = "machine-learning"
  application_name  = "${var.business_code}-sample-application"
  billing_code      = "1234"
  primary_contact   = "example@example.com"
  secondary_contact = "example2@example.com"
  business_code     = var.business_code
}

