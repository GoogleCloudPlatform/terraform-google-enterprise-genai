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

data "google_netblock_ip_ranges" "legacy_health_checkers" {
  range_type = "legacy-health-checkers"
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}

// Cloud IAP's TCP forwarding netblock
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}

locals {
  # List of services supported by VPC Service Controls.
  # This list is hardcoded and may need manual updates as Google Cloud adds support for new services.
  # For the latest list of supported products, please refer to:
  # https://cloud.google.com/vpc-service-controls/docs/supported-products
  supported_restricted_service = [
    "serviceusage.googleapis.com",
    "essentialcontacts.googleapis.com",
    "accessapproval.googleapis.com",
    "adsdatahub.googleapis.com",
    "aiplatform.googleapis.com",
    "alloydb.googleapis.com",
    "analyticshub.googleapis.com",
    "apigee.googleapis.com",
    "apigeeconnect.googleapis.com",
    "artifactregistry.googleapis.com",
    "assuredworkloads.googleapis.com",
    "automl.googleapis.com",
    "baremetalsolution.googleapis.com",
    "batch.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigtable.googleapis.com",
    "binaryauthorization.googleapis.com",
    "cloud.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddebugger.googleapis.com",
    "clouddeploy.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudprofiler.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudsearch.googleapis.com",
    "cloudtrace.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "connectgateway.googleapis.com",
    "contactcenterinsights.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerfilesystem.googleapis.com",
    "containerregistry.googleapis.com",
    "containerthreatdetection.googleapis.com",
    "datacatalog.googleapis.com",
    "dataflow.googleapis.com",
    "datafusion.googleapis.com",
    "datamigration.googleapis.com",
    "dataplex.googleapis.com",
    "dataproc.googleapis.com",
    "datastream.googleapis.com",
    "dialogflow.googleapis.com",
    "dlp.googleapis.com",
    "dns.googleapis.com",
    "documentai.googleapis.com",
    "domains.googleapis.com",
    "eventarc.googleapis.com",
    "file.googleapis.com",
    "firebaseappcheck.googleapis.com",
    "firebaserules.googleapis.com",
    "firestore.googleapis.com",
    "gameservices.googleapis.com",
    "gkebackup.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "healthcare.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "iaptunnel.googleapis.com",
    "ids.googleapis.com",
    "integrations.googleapis.com",
    "kmsinventory.googleapis.com",
    "krmapihosting.googleapis.com",
    "language.googleapis.com",
    "lifesciences.googleapis.com",
    "logging.googleapis.com",
    "managedidentities.googleapis.com",
    "memcache.googleapis.com",
    "meshca.googleapis.com",
    "meshconfig.googleapis.com",
    "metastore.googleapis.com",
    "ml.googleapis.com",
    "monitoring.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networkmanagement.googleapis.com",
    "networksecurity.googleapis.com",
    "networkservices.googleapis.com",
    "notebooks.googleapis.com",
    "opsconfigmonitoring.googleapis.com",
    "orgpolicy.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "privateca.googleapis.com",
    "pubsub.googleapis.com",
    "pubsublite.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    "recommender.googleapis.com",
    "redis.googleapis.com",
    "retail.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicecontrol.googleapis.com",
    "servicedirectory.googleapis.com",
    "spanner.googleapis.com",
    "speakerid.googleapis.com",
    "speech.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "storagetransfer.googleapis.com",
    "sts.googleapis.com",
    "texttospeech.googleapis.com",
    "timeseriesinsights.googleapis.com",
    "tpu.googleapis.com",
    "trafficdirector.googleapis.com",
    "transcoder.googleapis.com",
    "translate.googleapis.com",
    "videointelligence.googleapis.com",
    "vision.googleapis.com",
    "visionai.googleapis.com",
    "vmmigration.googleapis.com",
    "vpcaccess.googleapis.com",
    "webrisk.googleapis.com",
    "workflows.googleapis.com",
    "workstations.googleapis.com",
    "confidentialcomputing.googleapis.com",
  ]

  restricted_services         = length(var.custom_restricted_services) != 0 ? var.custom_restricted_services : local.supported_restricted_service
  restricted_services_dry_run = length(var.custom_restricted_services_dry_run) != 0 ? var.custom_restricted_services_dry_run : local.supported_restricted_service


  access_level_name         = var.access_level_name
  access_level_dry_run_name = var.access_level_name_dry_run
  perimeter_projects = {
    prj-kms              = var.kms_project_number
    prj-logs             = var.logging_project_number
    prj-machine-learning = var.machine_learning_project_number
  }

  ingress_keys = [
    "artifacts_to_kms",
    "service_catalog_to_kms",
  ]

  egress_keys = [
    "logging_to_service_catalog",
  ]

  ingress_policies_keys = concat(
    local.ingress_keys,
    var.ingress_policies_keys,
  )

  ingress_policies_keys_dry_run = concat(
    local.ingress_keys,
    var.ingress_policies_keys_dry_run,
  )

  egress_policies_keys = concat(
    local.egress_keys,
    var.egress_policies_keys,
  )

  egress_policies_keys_dry_run = concat(
    local.egress_keys,
    var.egress_policies_keys_dry_run,
  )

  required_ingress_rules_dry_run = [
    {
      title = "IR artifact to kms"
      from = {
        identities = [
          "serviceAccount:service-${var.artifact_publish_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
        ]
        sources = {
          resources = [
            "projects/${var.artifact_publish_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.kms_project_number}"
        ]
        operations = {
          "cloudkms.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    },
    {
      title = "IR service catalog to kms"
      from = {
        identities = [
          "serviceAccount:service-${var.service_catalog_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
        ]
        sources = {
          resources = [
            "projects/${var.service_catalog_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.kms_project_number}"
        ]
        operations = {
          "cloudkms.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    }
  ]

  required_ingress_rules = [
    {
      title = "IR artifact to kms"
      from = {
        identities = [
          "serviceAccount:service-${var.artifact_publish_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
        ]
        sources = {
          resources = [
            "projects/${var.artifact_publish_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.kms_project_number}"
        ]
        operations = {
          "cloudkms.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    },
    {
      title = "IR service catalog to kms"
      from = {
        identities = [
          "serviceAccount:service-${var.service_catalog_project_number}@gcp-sa-cloudbuild.iam.gserviceaccount.com",
        ]
        sources = {
          resources = [
            "projects/${var.service_catalog_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.kms_project_number}"
        ]
        operations = {
          "cloudkms.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    }
  ]

  required_egress_rules_dry_run = [
    {
      title = "ER logging to service catalog"
      from = {
        identities = [
          "serviceAccount:${var.terraform_service_account}",
        ]
        sources = {
          resources = [
            "projects/${var.logging_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.service_catalog_project_number}"
        ]
        operations = {
          "storage.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    },
  ]

  required_egress_rules = [
    {
      title = "ER logging to service catalog"
      from = {
        identities = [
          "serviceAccount:${var.terraform_service_account}",
        ]
        sources = {
          resources = [
            "projects/${var.logging_project_number}"
          ]
        }
      }
      to = {
        resources = [
          "projects/${var.service_catalog_project_number}"
        ]
        operations = {
          "storage.googleapis.com" = {
            methods = ["*"]
          }
        }
      }
    },
  ]
}

module "service_control" {
  source = "./modules/service_controls"

  count = var.machine_learning_perimeter == "" ? 1 : 0

  access_context_manager_policy_id = var.access_context_manager_policy_id
  restricted_services              = local.restricted_services
  restricted_services_dry_run      = local.restricted_services_dry_run
  members = distinct(concat([
    "serviceAccount:${var.terraform_service_account}",
  ], var.perimeter_additional_members))
  members_dry_run = distinct(concat([
    "serviceAccount:${var.terraform_service_account}",
  ], var.perimeter_additional_members))
  resources = [
    for project_key in keys(local.perimeter_projects) :
    "${local.perimeter_projects[project_key]}"
  ]
  resources_dry_run = [
    for project_key in keys(local.perimeter_projects) :
    "${local.perimeter_projects[project_key]}"
  ]
  resource_keys                 = keys(local.perimeter_projects)
  resource_keys_dry_run         = keys(local.perimeter_projects)
  ingress_policies_keys         = local.ingress_policies_keys
  ingress_policies_keys_dry_run = local.ingress_policies_keys_dry_run
  egress_policies_keys          = local.egress_policies_keys
  egress_policies_keys_dry_run  = local.egress_policies_keys_dry_run
  ingress_policies = concat(
    var.ingress_policies,
    local.required_ingress_rules,
  )
  ingress_policies_dry_run = concat(
    var.ingress_policies_dry_run,
    local.required_ingress_rules_dry_run,
  )
  egress_policies = concat(
    var.egress_policies,
    local.required_egress_rules,
  )
  egress_policies_dry_run = concat(
    var.egress_policies_dry_run,
    local.required_egress_rules_dry_run,
  )
  enforce_vpcsc               = var.enforce_vpcsc
  machine_learning_project_id = var.machine_learning_project_id
  network_name                = var.network_name
  allow_all_ingress_ranges    = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4)
  allow_all_egress_ranges     = ["0.0.0.0/0"]
}
