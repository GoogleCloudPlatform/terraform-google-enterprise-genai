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

// Composer

output "composer" {
  value       = try(module.base_env.composer, "")
  description = "Cloud Composer Environment."
}

########################
#      Metadata        #
########################

output "metadata" {
  description = "an identifier for the resource with format {{name}}"
  value       = try(module.base_env.metadata, "")
}

########################
#       Bucket         #
########################

output "bucket" {
  description = "Generated unique name fort the bucket"
  value       = try(module.base_env.bucket, "")
}

########################
#      TensorBoard     #
########################

output "tensorboard" {
  description = "TensorBoard resource."
  value       = try(module.base_env.tensorboard, "")
}
