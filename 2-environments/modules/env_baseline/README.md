<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| assured\_workload\_configuration | Assured Workload configuration. See https://cloud.google.com/assured-workloads ."<br>  enabled: If the assured workload should be created.<br>  location: The location where the workload will be created.<br>  display\_name: User-assigned resource display name.<br>  compliance\_regime: Supported Compliance Regimes. See https://cloud.google.com/assured-workloads/docs/reference/rest/Shared.Types/ComplianceRegime .<br>  resource\_type: The type of resource. One of CONSUMER\_FOLDER, KEYRING, or ENCRYPTION\_KEYS\_PROJECT. | <pre>object({<br>    enabled           = optional(bool, false)<br>    location          = optional(string, "us-central1")<br>    display_name      = optional(string, "FEDRAMP-MODERATE")<br>    compliance_regime = optional(string, "FEDRAMP_MODERATE")<br>    resource_type     = optional(string, "CONSUMER_FOLDER")<br>  })</pre> | `{}` | no |
| env | The environment to prepare (ex. development) | `string` | n/a | yes |
| environment\_code | A short form of the folder level resources (environment) within the Google Cloud organization (ex. d). | `string` | n/a | yes |
| monitoring\_workspace\_users | Google Workspace or Cloud Identity group that have access to Monitoring Workspaces. | `string` | n/a | yes |
| project\_budget | Budget configuration for projects.<br>  budget\_amount: The amount to use as the budget.<br>  alert\_spent\_percents: A list of percentages of the budget to alert on when threshold is exceeded.<br>  alert\_pubsub\_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.<br>  alert\_spend\_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default). | <pre>object({<br>    base_network_budget_amount                  = optional(number, 1000)<br>    base_network_alert_spent_percents           = optional(list(number), [1.2])<br>    base_network_alert_pubsub_topic             = optional(string, null)<br>    base_network_budget_alert_spend_basis       = optional(string, "FORECASTED_SPEND")<br>    restricted_network_budget_amount            = optional(number, 1000)<br>    restricted_network_alert_spent_percents     = optional(list(number), [1.2])<br>    restricted_network_alert_pubsub_topic       = optional(string, null)<br>    restricted_network_budget_alert_spend_basis = optional(string, "FORECASTED_SPEND")<br>    monitoring_budget_amount                    = optional(number, 1000)<br>    monitoring_alert_spent_percents             = optional(list(number), [1.2])<br>    monitoring_alert_pubsub_topic               = optional(string, null)<br>    monitoring_budget_alert_spend_basis         = optional(string, "FORECASTED_SPEND")<br>    secret_budget_amount                        = optional(number, 1000)<br>    secret_alert_spent_percents                 = optional(list(number), [1.2])<br>    secret_alert_pubsub_topic                   = optional(string, null)<br>    secret_budget_alert_spend_basis             = optional(string, "FORECASTED_SPEND")<br>    kms_budget_amount                           = optional(number, 1000)<br>    kms_alert_spent_percents                    = optional(list(number), [1.2])<br>    kms_alert_pubsub_topic                      = optional(string, null)<br>    kms_budget_alert_spend_basis                = optional(string, "FORECASTED_SPEND")<br> logging_budget_amount                       = optional(number, 1000)<br>  logging_alert_spent_percents                = optional(list(number), [1.2])<br>logging_alert_pubsub_topic                  = optional(string, null)<br>    logging_budget_alert_spend_basis            = optional(string, "FORECASTED_SPEND")<br>})</pre> | `{}` | no |
| remote\_state\_bucket | Backend bucket to load Terraform Remote State Data from previous steps. | `string` | n/a | yes |
| tfc\_org\_name | Name of the TFC organization | `string` | n/a | yes |
| keyring\_name | Name to be used for KMS Keyring | `string` | sample-keyring | yes |
| keyring\_regions | Regions to create Keyrings In | `list(string)` | ["us-central1", "us-east4"] | yes |
| gcs\_bucket\_prefix | Bucket prefix | `string` | bkt | yes |
| gcs\_bucket\_location | Location of environment logging bucket | `string` | us-central-1 | yes
| gcs\_logging\_retention_period | Retention configuration for environment logging bucket | <pre>object({<br>    is_locked             = bool<br>    retention_period_days = number<br>})</pre> | n/a | no |
| gcs\_logging\_key\_rotation\_period | Rotation period in seconds to be used for KMS Key | `string` | 7776000s | yes |

## Outputs

| Name | Description |
|------|-------------|
| assured\_workload\_id | Assured Workload ID. |
| assured\_workload\_resources | Resources associated with the Assured Workload. |
| env\_folder | Environment folder created under parent. |
| env\_kms\_project\_id | Project for environment Cloud Key Management Service (KMS). |
| env\_secrets\_project\_id | Project for environment secrets. |
| monitoring\_project\_id | Project for monitoring infra. |
| key\_rings | KMS Keyring Names created |
| env\_logs\_bucket\_name | Name of environment log bucket" |
| env\_logs\_project\_id | Project ID for environment logging. |
| env\_logs\_project\_number | Project number for environment logging.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
