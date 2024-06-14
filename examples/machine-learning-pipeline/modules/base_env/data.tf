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

data "google_project" "project" {
  project_id = var.project_id
}

data "google_projects" "non-production" {
  filter = "labels.application_name:machine-learning labels.env_code:n"
}

data "google_projects" "production" {
  filter = "labels.application_name:machine-learning labels.env_code:p"
}

data "google_service_account" "non-production" {
  project    = var.non-production_project_id
  account_id = "${var.non-production_project_number}-compute@developer.gserviceaccount.com"
}

data "google_service_account" "production" {
  project    = var.production_project_id
  account_id = "${var.production_project_number}-compute@developer.gserviceaccount.com"
}
