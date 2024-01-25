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

// The DNS name of peering managed zone. Must end with a period.
domain = "mlfoundation.badal.io."

// Update the following line and add you email in the perimeter_additional_members list.
// You must be in this list to be able to view/access resources in the project protected by the VPC service controls.

perimeter_additional_members = [
  "user:adam.hussein@badal.io",
  "user:kevin.cheema@badal.io",
  "user:majid.alikhani@badal.io",
  "user:mike.futerko@badal.io",
  "user:renato.dattilo@badal.io",
  "user:zbutt@badal.io",
  "serviceAccount:sa-tf-cb-bu3-machine-learning@prj-c-bu3infra-pipeline-c8kq.iam.gserviceaccount.com", // bu3infra-pipeline pipeline sa
  "serviceAccount:sa-terraform-env@prj-b-seed-fb52.iam.gserviceaccount.com",                           // prj-b-cicd-gybw pipeline sa
  "serviceAccount:service-352151227625@gs-project-accounts.iam.gserviceaccount.com",                   // dev env logging bucket gcs project service account
  "serviceAccount:234217653834@cloudbuild.gserviceaccount.com",                                        // Cloud Build SA
]

remote_state_bucket = "bkt-prj-b-seed-tfstate-ef26"
