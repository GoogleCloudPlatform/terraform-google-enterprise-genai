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

output "project_id" {
  description = "Project ID."
  value       = module.project.project_id
}

output "sa" {
  description = "Project SA email"
  value       = module.project.service_account_email
}

output "project_number" {
  description = "Project sample project number."
  value       = module.project.project_number
}

output "enabled_apis" {
  description = "VPC Service Control services."
  value       = distinct(concat(var.activate_apis, ["billingbudgets.googleapis.com"]))
}

output "project_name" {
  description = "Name of the Project."
  value       = module.project.project_name
}

output "kms_keys" {
  description = "Keys created for the project."
  value       = module.kms_keys.kms_keys
}
