## Prerequisites

### IAM Permissions

| Service Account | Scope | Role |
|-----------------|-------|------|
| service-ML_PRJ_NUMBER@compute-system.iam.gserviceaccount.com | Key | roles/cloudkms.cryptoKeyEncrypterDecrypter |
| service-ML_PRJ_NUMBER@gcp-sa-notebooks.iam.gserviceaccount.com | Key | roles/cloudkms.cryptoKeyEncrypterDecrypter |

### Organizational policies

| Policy constraint | Scope | Value |
|-------------------|-------|-------|
| constraints/ainotebooks.requireAutoUpgradeSchedule | Project | Google-managed |
| constraints/ainotebooks.environmentOptions | Project | Google-managed |

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| accelerator\_type | The type of accelerator to use. | `string` | `"NVIDIA_TESLA_K80"` | no |
| boot\_disk\_size\_gb | (Optional) The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB). | `string` | `"150"` | no |
| boot\_disk\_type | Possible disk types for notebook instances. | `string` | `"PD_SSD"` | no |
| boundry\_code | The boundry code for the tenant | `string` | `"001"` | no |
| core\_count | Number of accelerators to use. | `number` | `1` | no |
| data\_disk\_size\_gb | (Optional) The size of the data disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB) | `string` | `"150"` | no |
| data\_disk\_type | (Optional) Input only. Indicates the type of the disk. Possible values are: PD\_STANDARD, PD\_SSD, PD\_BALANCED, PD\_EXTREME. | `string` | `"PD_SSD"` | no |
| disable\_proxy\_access | (Optional) The notebook instance will not register with the proxy | `bool` | `false` | no |
| image\_family | Use this VM image family to find the image; the newest image in this family will be used. | `string` | `"workbench-instances"` | no |
| image\_name | Use VM image name to find the image. | `string` | `""` | no |
| image\_project | The name of the Google Cloud project that this VM image belongs to. Format: projects/{project\_id}. | `string` | `"cloud-notebooks-managed"` | no |
| install\_gpu\_driver | Whether the end user authorizes Google Cloud to install GPU driver on this instance. Only applicable to instances with GPUs. | `bool` | `false` | no |
| instance\_owners | Email of the owner of the instance, e.g. alias@example.com. Only one owner is supported! | `set(string)` | n/a | yes |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as var.location and the same environment.<br>    This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION". | `string` | n/a | yes |
| location | Notebook instance location (zone). | `string` | `"us-central1-a"` | no |
| machine\_type | Type of the machine to spin up for the notebook. | `string` | `"e2-standard-4"` | no |
| name | Name of the notebook instance. | `string` | n/a | yes |
| project\_id | Project ID to deploy the instance. | `string` | n/a | yes |
| tags | The Compute Engine tags to add to instance. | `list(string)` | <pre>[<br>  "egress-internet"<br>]</pre> | no |
| vpc\_project | This is the project id of the Restricted Shared VPC Host Project for your environment.<br>  This value can be obtained by running "gcloud projects list --filter='labels.application\_name:restricted-shared-vpc-host lifecycleState:ACTIVE'" and selecting the project. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| create\_time | Instance creation time |
| effective\_labels | All of labels (key/value pairs) present on the resource in GCP, including the labels configured through Terraform, other clients and services. |
| id | an identifier for the resource with format projects/{{project}}/locations/{{location}}/instances/{{name}} |
| proxy\_uri | The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value. |
| state | The state of this instance. |
| terraform\_labels | The combination of labels configured directly on the resource and default labels configured on the provider. |
| update\_time | Instance update time. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
