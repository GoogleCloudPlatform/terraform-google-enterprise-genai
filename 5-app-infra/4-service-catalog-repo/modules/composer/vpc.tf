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

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.1"

  project_id   = data.google_project.project.project_id
  network_name = local.network_name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "composer-primary-use4"
      subnet_ip             = local.composer_node_use4
      subnet_region         = "us-east4"
      subnet_private_access = true
      subnet_flow_logs      = "true"
    },
    {
      subnet_name           = "composer-primary-usc1"
      subnet_ip             = local.composer_node_usc1
      subnet_region         = "us-central1"
      subnet_private_access = true
      subnet_flow_logs      = "true"
    }
  ]

  secondary_ranges = {
    composer-primary-use4 = [
      {
        range_name    = "pods-primary-use4"
        ip_cidr_range = local.pods_use4
      },
      {
        range_name    = "composer-services-primary-use4"
        ip_cidr_range = local.services_use4
      },
    ]

    composer-primary-usc1 = [
      {
        range_name    = "pods-primary-usc1"
        ip_cidr_range = local.pods_usc1
      },
      {
        range_name    = "composer-services-primary-usc1"
        ip_cidr_range = local.services_usc1
      }
    ]
  }

  ingress_rules = [
    {
      name               = "allow-internal"
      description        = "Allow internal traffic within the VPC"
      source_tags        = ["internal"]
      destination_ranges = ["10.0.0.0/8"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name          = "iap-all-to-all"
      description   = "Allow support for IAP connections via google source ranges"
      source_ranges = data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4
      allow = [
        {
          protocol = "tcp"
          ports    = ["22"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name          = "health-check-google-to-all"
      description   = "Allow support for Health Check connections via google source ranges"
      source_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4)
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]

  egress_rules = [
    {
      name               = "egress-health-check-composer-to-google"
      description        = "Allow egress for Health Check connections from composer clusters"
      target_tags        = ["composer-use4", "composer-usc1"]
      destination_ranges = concat(data.google_netblock_ip_ranges.health_checkers.cidr_blocks_ipv4, data.google_netblock_ip_ranges.legacy_health_checkers.cidr_blocks_ipv4)
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }

    },
    {
      name               = "composer-to-dns"
      description        = "Composer DNS access"
      destination_ranges = [local.composer_node_usc1, local.composer_node_use4]
      allow = [
        {
          protocol = "tcp"
          ports    = ["53"]
        },
        {
          protocol = "udp"
          ports    = ["53"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-use4-node-to-node"
      description        = "Composer node to node all comms in USE4"
      target_tags        = ["composer-use4"]
      destination_ranges = [local.composer_node_use4]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-usc1-node-to-node"
      description        = "Composer node to node all comms in USC1"
      target_tags        = ["composer-usc1"]
      destination_ranges = [local.composer_node_usc1]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-use4-node-to-master"
      description        = "Composer node to master all comms in USE4"
      target_tags        = ["composer-use4"]
      destination_ranges = [local.composer_master_use4]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-usc1-node-to-master"
      description        = "Composer node to master all comms in USC1"
      target_tags        = ["composer-usc1"]
      destination_ranges = [local.composer_master_usc1]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-use4-to-webserver"
      description        = "Composer Nodes to Web Server in USE4"
      target_tags        = ["composer-use4"]
      destination_ranges = [local.composer_webserver_use4]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "composer-usc1-to-webserver"
      description        = "Composer Nodes to Web Server in USC1"
      target_tags        = ["composer-usc1"]
      destination_ranges = [local.composer_webserver_usc1]
      allow = [
        {
          protocol = "all"
          ports    = []
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "all-to-googleapi"
      description        = "Access for all resources in isolated VPC to Google APIs"
      destination_ranges = ["199.36.153.8/30", "199.36.153.4/30"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["443"]
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name        = "composer-v2-internal-egress"
      description = "Access for all resources in isolated VPC to Google APIs"
      target_tags = ["composer-usc1", "composer-use4"]
      destination_ranges = [
        "10.0.0.0/8",
        "172.16.0.0/12",
        "192.168.0.0/16"
      ]
      allow = [
        {
          protocol = "all"
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name               = "deny-all-egress"
      description        = "Default deny egress"
      target_tags        = ["composer-usc1", "composer-use4"]
      destination_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "all"
        }
      ]
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}
