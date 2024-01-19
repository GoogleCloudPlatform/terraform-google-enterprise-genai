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

resource "google_secret_manager_secret" "secret" {
  for_each  = toset(var.secret_names)
  secret_id = each.key

  project = data.google_project.project.project_id

  #Set up Automatic Rotation of Secrets
  #Control ID: SM-CO-6.2
  #NIST 800-53: SC-12 SC-13

  rotation {
    next_rotation_time = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timeadd(timestamp(), "720h"))
    rotation_period    = "43200s"

  }

  topics {
    name = google_pubsub_topic.secret-rotations.id
  }

  #Automatic Secret Replication
  #Control ID: SM-CO-6.1
  #NIST 800-53: SC-12 SC-13

  replication {
    user_managed {
      replicas {
        location = data.google_kms_key_ring.kms.location

        #Customer Managed Encryption Keys
        #Control ID: COM-CO-2.3
        #NIST 800-53: SC-12 SC-13
        #CRI Profile: PR.DS-1.1 PR.DS-1.2 PR.DS-2.1 PR.DS-2.2 PR.DS-5.1

        customer_managed_encryption {
          kms_key_name = data.google_kms_crypto_key.key.id
        }
      }
    }
  }

  depends_on = [
    google_pubsub_topic_iam_binding.pubsub_binding,
    google_pubsub_topic.secret-rotations
  ]
}

resource "google_pubsub_topic" "secret_rotations" {
  name    = "secret-rotation-notifications"
  project = data.google_project.project.project_id
}

resource "google_pubsub_topic_iam_binding" "pubsub_binding" {
  topic   = google_pubsub_topic.secret-rotations.name
  project = data.google_project.project.project_id
  role    = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_project_service_identity.agent.email}"
  ]
}
