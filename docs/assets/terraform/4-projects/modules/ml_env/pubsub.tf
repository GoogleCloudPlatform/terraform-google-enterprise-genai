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

locals {
  pubsub_topic_name = "secret-rotation-notifications"
}

// Secret rotation notification
resource "google_pubsub_topic" "secret_rotations" {
  name    = local.pubsub_topic_name
  project = module.machine_learning_project.project_id
}

resource "google_pubsub_topic_iam_member" "pubsub_binding" {
  topic   = google_pubsub_topic.secret_rotations.name
  project = module.machine_learning_project.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${module.machine_learning_project.project_number}@gcp-sa-secretmanager.iam.gserviceaccount.com"

  depends_on = [time_sleep.wait_30_seconds]
}
