/**
 * Copyright 2026 Google LLC
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

org_id                                 = "REPLACE_ME" # format "000000000000"
billing_account                        = "REPLACE_ME" # format "000000-000000-000000"
parent_folder                          = "REPLACE_ME" # format "000000000000"
terraform_service_account              = "REPLACE_ME"
access_context_manager_policy_id       = ACCESS_CONTEXT_MANAGER_ID
perimeter_additional_members           = ["user:YOUR-USER-EMAIL@example.com"]
default_region                         = "us-central1"
cloud_source_artifacts_repo_name       = "publish-artifacts"
cloud_source_service_catalog_repo_name = "service-catalog"
instance_region                        = "us-central1"
