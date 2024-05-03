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

output "project_id" {
  description = "Project ID of composer project"
  value       = module.app_cloudbuild_project.project_id
}

output "project_number" {
  description = "Project number of composer project"
  value       = module.app_cloudbuild_project.project_number
}

output "project_name" {
  description = "Project name of composer project"
  value       = module.app_cloudbuild_project.project_name
}

output "project_sa" {
  description = "SA of the composer project"
  value       = module.app_cloudbuild_project.sa
}

output "project_crypto_key" {
  description = "key created in project"
  value       = module.app_cloudbuild_project.kms_keys
}

# output "terraform_service_accounts" {
#   description = "Composer Terraform SA mapped to source repos as keys"
#   value       = try(module.app_pipelines.terraform_service_accounts, {})
# }

# output "repos" {
#   description = "CSR's to store source code for composer repo"
#   value       = try(module.app_pipelines.repos, toset([]))
# }

# output "artifact_buckets" {
#   description = "GCS Buckets to store Cloud Build Artifacts"
#   value       = try(module.app_pipelines.artifact_buckets, {})
# }

# output "state_buckets" {
#   description = "GCS Buckets to store TF state"
#   value       = try(module.app_pipelines.state_buckets, {})
# }

# output "log_buckets" {
#   description = "GCS Buckets to store Cloud Build logs"
#   value       = try(module.app_pipelines.log_buckets, {})
# }

# output "plan_triggers_id" {
#   description = "CB plan triggers"
#   value       = try(module.app_pipelines.plan_triggers_id, [])
# }

# output "apply_triggers_id" {
#   description = "CB apply triggers"
#   value       = try(module.app_pipelines.apply_triggers_id, [])
# }

output "enable_cloudbuild_deploy" {
  description = "Enable infra deployment using Cloud Build."
  value       = local.enable_cloudbuild_deploy
}
