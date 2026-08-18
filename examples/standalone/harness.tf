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

locals {
  seed_project_name             = var.seed_project_name != "" ? var.seed_project_name : "${var.project_prefix}-seed-${random_id.project_id_suffix.hex}"
  kms_project_name              = var.kms_project_name != "" ? var.kms_project_name : "${var.project_prefix}-kms-${random_id.project_id_suffix.hex}"
  logging_project_name          = var.logging_project_name != "" ? var.logging_project_name : "${var.project_prefix}-logging-${random_id.project_id_suffix.hex}"
  machine_learning_project_name = var.machine_learning_project_name != "" ? var.machine_learning_project_name : "${var.project_prefix}-machine-learning-${random_id.project_id_suffix.hex}"
  service_catalog_project_name  = var.service_catalog_project_name != "" ? var.service_catalog_project_name : "${var.project_prefix}-service-catalog-${random_id.project_id_suffix.hex}"
  artifact_publish_project_name = var.artifact_publish_project_name != "" ? var.artifact_publish_project_name : "${var.project_prefix}-publish-artifacts-${random_id.project_id_suffix.hex}"
  state_bucket_name             = "${var.gcs_bucket_prefix}-${var.project_prefix}-tfstate"

  terraform_sa_project_roles = [
    "roles/storage.admin",
    "roles/cloudkms.admin",
  ]

  terraform_state_kms_key = module.kms.keys["${var.project_prefix}-key"]
}

resource "random_id" "project_id_suffix" {
  byte_length = 2
}

/******************************************
  Project for state bucket
*****************************************/

module "seed_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.seed_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["cloudkms.googleapis.com", "serviceusage.googleapis.com", "iamcredentials.googleapis.com", "storage.googleapis.com"]
}

module "kms" {
  source  = "terraform-google-modules/kms/google"
  version = "~> 4.0"

  project_id          = module.seed_project.project_id
  location            = var.default_region
  keyring             = "${var.project_prefix}-keyring"
  keys                = ["${var.project_prefix}-key"]
  key_rotation_period = "7776000s"

  prevent_destroy = var.kms_prevent_destroy
}

resource "google_storage_bucket" "terraform_state" {
  project                     = module.seed_project.project_id
  name                        = local.state_bucket_name
  location                    = var.default_region
  labels                      = var.storage_bucket_labels
  force_destroy               = var.bucket_force_destroy
  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }

  dynamic "encryption" {
    for_each = var.encrypt_gcs_bucket_tfstate ? ["encryption"] : []
    content {
      default_kms_key_name = local.terraform_state_kms_key
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.terraform_state_gcs_kms]
}

data "google_storage_project_service_account" "gcs_account" {
  project = module.seed_project.project_id
}

resource "google_kms_crypto_key_iam_member" "terraform_state_gcs_kms" {
  crypto_key_id = local.terraform_state_kms_key
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

resource "google_project_iam_member" "terraform_sa_project_roles" {
  for_each = toset(local.terraform_sa_project_roles)

  project = module.seed_project.project_id
  role    = each.value
  member  = "serviceAccount:${var.terraform_service_account}"
}

/******************************************
  Project for KMS
*****************************************/

module "kms_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.kms_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["logging.googleapis.com", "cloudkms.googleapis.com", "billingbudgets.googleapis.com"]
}

/******************************************
  Project for Logs Storage
*****************************************/

module "logging_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.logging_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy
  activate_apis           = ["logging.googleapis.com", "bigquery.googleapis.com", "billingbudgets.googleapis.com"]
}


/******************************************
  Project Machine Learning
*****************************************/

module "machine_learning_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.machine_learning_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "keep"
  deletion_policy         = var.project_deletion_policy

  activate_apis = [
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "composer.googleapis.com",
    "compute.googleapis.com",
    "containerregistry.googleapis.com",
    "dataflow.googleapis.com",
    "dataform.googleapis.com",
    "deploymentmanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "notebooks.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "dns.googleapis.com",
  ]
}


/******************************************
  Project for Publish Artifacts
*****************************************/

module "artifact_publish_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.artifact_publish_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy

  activate_apis = [
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "billingbudgets.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
}

/******************************************
  Project Service Catalog
*****************************************/

module "service_catalog_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                    = local.service_catalog_project_name
  org_id                  = var.org_id
  folder_id               = var.parent_folder
  billing_account         = var.billing_account
  default_service_account = "deprivilege"
  deletion_policy         = var.project_deletion_policy

  activate_apis = [
    "logging.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sourcerepo.googleapis.com",
  ]
}


locals {
  network_name               = "ml-vpc"
  restricted_googleapis_cidr = "199.36.153.4/30"
  subnet_ip                  = "10.0.32.0/28"

  private_service_range_name = "ml-private-service-range"
  private_service_cidr       = "10.24.192.0/24"
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 18.0"

  project_id                             = module.machine_learning_project.project_id
  network_name                           = local.network_name
  shared_vpc_host                        = "false"
  delete_default_internet_gateway_routes = "true"

  auto_create_subnetworks = "false"

  subnets = [
    {
      subnet_name           = "sb-restricted-${var.default_region}"
      subnet_ip             = local.subnet_ip
      subnet_region         = var.default_region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
      description           = "restricted subnet for machine learnig workloads."
    }
  ]

  routes = [{
    name              = "rt-${local.network_name}-1000-egress-internet-default"
    description       = "Tag based route through IGW to access internet"
    destination_range = "0.0.0.0/0"
    tags              = ["egress-internet"]
    next_hop_internet = "true"
    priority          = "1000"
    },
    {
      name              = "rt-${local.network_name}-1000-all-default-windows-kms"
      description       = "Route through IGW to allow Windows KMS activation for GCP."
      destination_range = "35.190.247.13/32"
      next_hop_internet = "true"
      priority          = "1000"
  }]
}

/******************************************
  Cloud NAT & Router
*****************************************/

resource "google_compute_router" "nat_router" {
  name    = "router-${local.network_name}-${var.default_region}"
  project = module.machine_learning_project.project_id
  region  = var.default_region
  network = module.network.network_self_link

  bgp {
    asn = var.nat_bgp_asn
  }
}

resource "google_compute_address" "nat_external_addresses" {
  project = module.machine_learning_project.project_id
  name    = "ca-${local.network_name}-${var.default_region}"
  region  = var.default_region
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-${local.network_name}-${var.default_region}"
  project                            = module.machine_learning_project.project_id
  router                             = google_compute_router.nat_router.name
  region                             = var.default_region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_external_addresses.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    filter = "TRANSLATIONS_ONLY"
    enable = true
  }
}
