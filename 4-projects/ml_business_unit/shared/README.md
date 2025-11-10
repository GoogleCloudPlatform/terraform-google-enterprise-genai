<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloud\_source\_artifacts\_repo\_name | Name to give the could source repository for Artifacts | `string` | n/a | yes |
| cloud\_source\_service\_catalog\_repo\_name | Name to give the cloud source repository for Service Catalog | `string` | n/a | yes |
| default\_region | Default region to create resources where applicable. | `string` | `"us-central1"` | no |
| gcs\_bucket\_prefix | Name prefix to be used for GCS Bucket | `string` | `"bkt"` | no |
| key\_rotation\_period | Rotation period in seconds to be used for KMS Key | `string` | `"7776000s"` | no |
| keyring\_name | Name to be used for KMS Keyring | `string` | `"sample-keyring"` | no |
| location\_gcs | Case-Sensitive Location for GCS Bucket | `string` | `"US"` | no |
| location\_kms | Case-Sensitive Location for KMS Keyring | `string` | `"us"` | no |
| prevent\_destroy | Prevent Project Key destruction. | `bool` | `true` | no |
| project\_budget | Budget configuration.<br>  budget\_amount: The amount to use as the budget.<br>  alert\_spent\_percents: A list of percentages of the budget to alert on when threshold is exceeded.<br>  alert\_pubsub\_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.<br>  alert\_spend\_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default). | <pre>object({<br>    budget_amount        = optional(number, 1000)<br>    alert_spent_percents = optional(list(number), [1.2])<br>    alert_pubsub_topic   = optional(string, null)<br>    alert_spend_basis    = optional(string, "FORECASTED_SPEND")<br>  })</pre> | `{}` | no |
| remote\_state\_bucket | Backend bucket to load Terraform Remote State Data from previous steps. | `string` | n/a | yes |
| tfc\_org\_name | Name of the TFC organization | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| apply\_triggers\_id | CB apply triggers |
| artifact\_buckets | GCS Buckets to store Cloud Build Artifacts |
| artifacts\_repo\_id | ID of the Artifacts repository |
| artifacts\_repo\_name | The name of the Artifacts repository |
| cloudbuild\_project\_id | n/a |
| common\_artifacts\_project\_id | App Infra Artifacts Project ID |
| default\_region | Default region to create resources where applicable. |
| enable\_cloudbuild\_deploy | Enable infra deployment using Cloud Build. |
| log\_bucket | Log bucket to be used by Service Catalog Bucket. |
| log\_buckets | GCS Buckets to store Cloud Build logs |
| plan\_triggers\_id | CB plan triggers |
| repos | CSRs to store source code |
| service\_catalog\_project\_id | Service Catalog Project ID. |
| service\_catalog\_repo\_id | ID of the Service Catalog repository |
| service\_catalog\_repo\_name | The name of the Service Catalog repository |
| shared\_level\_keyrings | Keyrings used on shared level project creation |
| state\_buckets | GCS Buckets to store TF state |
| terraform\_service\_accounts | APP Infra Pipeline Terraform Accounts. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
