<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | The api to activate for the GCP project | `list(string)` | `[]` | no |
| artifact\_publish\_project\_name | Custom project name for the artifact publish project. | `string` | `""` | no |
| billing\_account | The ID of the billing account to associated this project with | `string` | n/a | yes |
| bucket\_force\_destroy | If supplied, the state bucket will be deleted even while containing objects. | `bool` | `false` | no |
| default\_region | The region in which the subnetwork will be created. | `string` | n/a | yes |
| encrypt\_gcs\_bucket\_tfstate | Encrypt bucket used for storing terraform state files in seed project. | `bool` | `false` | no |
| folder\_id | The folder id where project will be created | `string` | n/a | yes |
| kms\_project\_name | Custom project name for kms project. | `string` | `""` | no |
| logging\_project\_name | Custom project name for the logging project. | `string` | `""` | no |
| machine\_learning\_project\_name | Custom project name for machine learning project. | `string` | `""` | no |
| org\_id | The organization id for the associated services | `string` | n/a | yes |
| project\_deletion\_policy | Project deletion policy. Possible values are: "PREVENT", "ABANDON", "DELETE" | `string` | `"PREVENT"` | no |
| project\_prefix | Name prefix to use for projects created. Should be the same in all steps. Max size is 3 characters. | `string` | `"prj"` | no |
| region | The region in which the subnetwork will be created. | `string` | n/a | yes |
| seed\_project\_name | Custom project name for seed project. | `string` | `""` | no |
| service\_catalog\_project\_name | Custom project name for the service catalog project. | `string` | `""` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_publish\_project\_id | Artifact Publish project ID. |
| artifact\_publish\_project\_name | Artifact Publish project Name. |
| artifact\_publish\_project\_number | Artifact Publish project number. |
| kms\_project\_id | KMS project ID. |
| kms\_project\_number | KMS project number. |
| logging\_project\_id | Logging project ID. |
| logging\_project\_name | Logging project number. |
| logging\_project\_number | Logging project number. |
| machine\_learning\_network\_name | The name of the machine learning VPC being created. |
| machine\_learning\_project\_id | Machine Learning project ID. |
| machine\_learning\_project\_name | Machine Learning project Name. |
| machine\_learning\_project\_number | Machine Learning project number. |
| machine\_learning\_subnet\_id | The id of the machine learning subnet being created. |
| machine\_learning\_subnet\_name | The name of the machine learning subnet being created. |
| machine\_learning\_subnets\_self\_link | The self-links of the machine learning subnets being created. |
| restricted\_network\_self\_link | The URI of the machine learning VPC being created. |
| seed\_project\_id | Seed project ID. |
| service\_catalog\_project\_id | Service Catalog project ID. |
| service\_catalog\_project\_name | Service Catalog project number. |
| service\_catalog\_project\_number | Service Catalog project number. |
| state\_bucket | State bucket |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
