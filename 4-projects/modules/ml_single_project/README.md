# Machine Learning Single Project

Create and manage a Google Cloud project with various configurations and roles required for application infrastructure and pipeline service accounts. It includes the setup of IAM roles, VPC networking, KMS keys, and budget alerts. The module leverages the terraform-google-modules/project-factory/google module for project creation and management.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | The api to activate for the GCP project. | `list(string)` | `[]` | no |
| app\_infra\_pipeline\_service\_accounts | The Service Accounts from App Infra Pipeline. | `map(string)` | `{}` | no |
| application\_name | The name of application where GCP resources relate. | `string` | n/a | yes |
| billing\_account | The ID of the billing account to associated this project with. | `string` | n/a | yes |
| billing\_code | The code that's used to provide chargeback information. | `string` | n/a | yes |
| business\_code | The code that describes which business unit owns the project. | `string` | `"abcd"` | no |
| default\_service\_account | Project default service account setting: can be one of `delete`, `depriviledge`, `keep` or `disable`. | `string` | `"disable"` | no |
| enable\_cloudbuild\_deploy | Enable infra deployment using Cloud Build. | `bool` | `false` | no |
| environment | The environment the project belongs to. | `string` | n/a | yes |
| environment\_kms\_project\_id | Environment level KMS Project ID. | `string` | n/a | yes |
| folder\_id | The folder id where project will be created. | `string` | n/a | yes |
| key\_rings | Keyrings to attach project key to. | `list(string)` | n/a | yes |
| key\_rotation\_period | Rotation period in seconds to be used for KMS Key. | `string` | `"7776000s"` | no |
| org\_id | The Organization ID. | `string` | n/a | yes |
| prevent\_destroy | Prevent Key destruction. | `bool` | n/a | yes |
| primary\_contact | The primary email contact for the project. | `string` | n/a | yes |
| project\_budget | Budget configuration.<br>  budget\_amount: The amount to use as the budget.<br>  alert\_spent\_percents: A list of percentages of the budget to alert on when threshold is exceeded.<br>  alert\_pubsub\_topic: The name of the Cloud Pub/Sub topic where budget related messages will be published, in the form of `projects/{project_id}/topics/{topic_id}`.<br>  alert\_spend\_basis: The type of basis used to determine if spend has passed the threshold. Possible choices are `CURRENT_SPEND` or `FORECASTED_SPEND` (default). | <pre>object({<br>    budget_amount        = optional(number, 1000)<br>    alert_spent_percents = optional(list(number), [1.2])<br>    alert_pubsub_topic   = optional(string, null)<br>    alert_spend_basis    = optional(string, "FORECASTED_SPEND")<br>  })</pre> | `{}` | no |
| project\_name | Project Name. | `string` | n/a | yes |
| project\_prefix | Name prefix to use for projects created. | `string` | `"prj"` | no |
| project\_suffix | The name of the GCP project. Max 16 characters with 3 character business unit code. | `string` | n/a | yes |
| remote\_state\_bucket | Backend bucket to load Terraform Remote State Data from previous steps. | `string` | n/a | yes |
| sa\_roles | A list of roles to give the Service Account from App Infra Pipeline. | `map(list(string))` | `{}` | no |
| secondary\_contact | The secondary email contact for the project. | `string` | `""` | no |
| shared\_vpc\_host\_project\_id | Shared VPC host project ID. | `string` | `""` | no |
| shared\_vpc\_subnets | List of the shared vpc subnets self links. | `list(string)` | `[]` | no |
| vpc\_service\_control\_attach\_enabled | Whether the project will be attached to a VPC Service Control Perimeter. | `bool` | `false` | no |
| vpc\_service\_control\_perimeter\_name | The name of a VPC Service Control Perimeter to add the created project to. | `string` | `null` | no |
| vpc\_service\_control\_sleep\_duration | The duration to sleep in seconds before adding the project to a shared VPC after the project is added to the VPC Service Control Perimeter. | `string` | `"5s"` | no |
| vpc\_type | The type of VPC to attach the project to. Possible options are `base` or `restricted`. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| enabled\_apis | VPC Service Control services. |
| kms\_keys | Keys created for the project. |
| project\_id | Project ID. |
| project\_name | Project Name. |
| project\_number | Project number. |
| sa | Project SA email. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
