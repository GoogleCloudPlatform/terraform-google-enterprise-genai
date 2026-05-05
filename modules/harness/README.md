<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| activate\_apis | The APIs to activate for the Google Cloud project. | `list(string)` | `[]` | no |
| artifact\_publish\_project\_name | Custom project name for the artifact publishing project. | `string` | `""` | no |
| billing\_account | The ID of the billing account to associate this project with. | `string` | n/a | yes |
| bucket\_force\_destroy | If supplied, the state bucket will be deleted even while containing objects. | `bool` | `false` | no |
| default\_region | The region in which the subnetwork will be created. | `string` | n/a | yes |
| encrypt\_gcs\_bucket\_tfstate | Encrypt the bucket used for storing Terraform state files in the seed project. | `bool` | `true` | no |
| folder\_id | The folder ID where the project will be created. | `string` | n/a | yes |
| kms\_prevent\_destroy | If set to true, delete the KMS key ring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present. | `bool` | `true` | no |
| kms\_project\_name | Custom project name for the KMS project. | `string` | `""` | no |
| logging\_project\_name | Custom project name for the logging project. | `string` | `""` | no |
| machine\_learning\_project\_name | Custom project name for the Machine Learning project. | `string` | `""` | no |
| org\_id | The organization ID for the associated services. | `string` | n/a | yes |
| project\_deletion\_policy | Project deletion policy. Possible values are: "PREVENT", "ABANDON", "DELETE". | `string` | `"PREVENT"` | no |
| project\_prefix | Name prefix to use for projects created. Should be the same in all steps. Max size is 3 characters. | `string` | `"prj"` | no |
| seed\_project\_name | Custom project name for the seed project. | `string` | `""` | no |
| service\_catalog\_project\_name | Custom project name for the Service Catalog project. | `string` | `""` | no |
| storage\_bucket\_labels | Labels to apply to the storage bucket. | `map(string)` | `{}` | no |
| terraform\_service\_account | The email address of the service account that will run the Terraform code. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_publish\_project\_id | Artifact publishing project ID. |
| artifact\_publish\_project\_name | Artifact publishing project name. |
| artifact\_publish\_project\_number | Artifact publishing project number. |
| kms\_project\_id | KMS project ID. |
| kms\_project\_number | KMS project number. |
| logging\_project\_id | Logging project ID. |
| logging\_project\_name | Logging project name. |
| logging\_project\_number | Logging project number. |
| machine\_learning\_network\_name | The name of the Machine Learning VPC being created. |
| machine\_learning\_project\_id | Machine Learning project ID. |
| machine\_learning\_project\_name | Machine Learning project name. |
| machine\_learning\_project\_number | Machine Learning project number. |
| machine\_learning\_subnet\_id | The ID of the Machine Learning subnet being created. |
| machine\_learning\_subnet\_name | The name of the Machine Learning subnet being created. |
| machine\_learning\_subnets\_self\_link | The self-links of the Machine Learning subnets being created. |
| remote\_state\_bucket | State bucket. |
| restricted\_network\_self\_link | The URI of the Machine Learning VPC being created. |
| seed\_project\_id | Seed project ID. |
| service\_catalog\_project\_id | Service Catalog project ID. |
| service\_catalog\_project\_name | Service Catalog project name. |
| service\_catalog\_project\_number | Service Catalog project number. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
