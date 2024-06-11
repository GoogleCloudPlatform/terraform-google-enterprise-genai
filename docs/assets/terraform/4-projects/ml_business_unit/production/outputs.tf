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

output "machine_learning_project_id" {
  description = "Project machine learning project."
  value       = module.ml_env.machine_learning_project_id
}

output "machine_learning_project_number" {
  description = "Project number of machine learning project."
  value       = module.ml_env.machine_learning_project_number
}

output "machine_learning_kms_keys" {
  description = "Key ID for the machine learning project."
  value       = module.ml_env.machine_learning_kms_keys
}

output "enable_cloudbuild_deploy" {
  description = "Enable infra deployment using Cloud Build."
  value       = local.enable_cloudbuild_deploy
}
