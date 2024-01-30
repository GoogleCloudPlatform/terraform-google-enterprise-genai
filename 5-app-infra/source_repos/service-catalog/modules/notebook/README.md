## Prerequisites

#### IAM Permissions

| Service Account | Scope | Role |
|-----------------|-------|------|
| PROJECT_NUMBER@cloudbuild.gserviceaccount.com | Project | Browser |
|  | Project | Service Usage Consumer |
|  | Project | Notebooks Admin |
|  | Project | Compute Network Admin |
|  | Project | Compute Security Admin |

#### Organizational policies

| Policy constraint | Scope | Value |
|-------------------|-------|-------|
| constraints/ainotebooks.requireAutoUpgradeSchedule | Project | Google-managed |
| constraints/ainotebooks.environmentOptions | Project | Google-managed |


<!-- BEGIN_TF_DOCS -->
Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 5.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_workbench_instance.instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/workbench_instance) | resource |
| [google_compute_network.shared_vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_netblock_ip_ranges.health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.iap_forwarders](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_netblock_ip_ranges.legacy_health_checkers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |
| [google_projects.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accelerator_type"></a> [accelerator\_type](#input\_accelerator\_type) | The type of accelerator to use | `string` | `"NVIDIA_TESLA_K80"` | no |
| <a name="input_boot_disk_size_gb"></a> [boot\_disk\_size\_gb](#input\_boot\_disk\_size\_gb) | (Optional) The size of the boot disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB) | `string` | `"100"` | no |
| <a name="input_boot_disk_type"></a> [boot\_disk\_type](#input\_boot\_disk\_type) | Possible disk types for notebook instances | `string` | `"PD_SSD"` | no |
| <a name="input_boundry_code"></a> [boundry\_code](#input\_boundry\_code) | The boundry code for the tenant | `string` | `"001"` | no |
| <a name="input_core_count"></a> [core\_count](#input\_core\_count) | number of accelerators to use | `number` | `1` | no |
| <a name="input_data_disk_size_gb"></a> [data\_disk\_size\_gb](#input\_data\_disk\_size\_gb) | (Optional) The size of the data disk in GB attached to this instance, up to a maximum of 64000 GB (64 TB) | `string` | `"100"` | no |
| <a name="input_data_disk_type"></a> [data\_disk\_type](#input\_data\_disk\_type) | Optional. Input only. Indicates the type of the disk. Possible values are: PD\_STANDARD, PD\_SSD, PD\_BALANCED, PD\_EXTREME. | `string` | `"PD_SSD"` | no |
| <a name="input_disable_proxy_access"></a> [disable\_proxy\_access](#input\_disable\_proxy\_access) | (Optional) The notebook instance will not register with the proxy | `bool` | `false` | no |
| <a name="input_image_family"></a> [image\_family](#input\_image\_family) | Use this VM image family to find the image; the newest image in this family will be used. | `string` | `"common-cpu-notebooks"` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Use VM image name to find the image. | `string` | `""` | no |
| <a name="input_image_project"></a> [image\_project](#input\_image\_project) | The name of the Google Cloud project that this VM image belongs to. Format: projects/{project\_id} | `string` | `"deeplearning-platform-release"` | no |
| <a name="input_install_gpu_driver"></a> [install\_gpu\_driver](#input\_install\_gpu\_driver) | Whether the end user authorizes Google Cloud to install GPU driver on this instance. Only applicable to instances with GPUs. | `bool` | `false` | no |
| <a name="input_instance_owners"></a> [instance\_owners](#input\_instance\_owners) | email of the owner of the instance, e.g. alias@example.com. Only one owner is supported! | `set(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Notebook instance location (zone). | `string` | `"us-central1-a"` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | type of the machine to spin up for the notebook | `string` | `"e2-standard-4"` | no |
| <a name="input_name"></a> [name](#input\_name) | name of the notebook instance | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional Project ID. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The Compute Engine tags to add to instance. | `list(string)` | <pre>[<br>  "egress-internet"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_create_time"></a> [create\_time](#output\_create\_time) | Instance creation time |
| <a name="output_effective_labels"></a> [effective\_labels](#output\_effective\_labels) | All of labels (key/value pairs) present on the resource in GCP, including the labels configured through Terraform, other clients and services. |
| <a name="output_id"></a> [id](#output\_id) | an identifier for the resource with format projects/{{project}}/locations/{{location}}/instances/{{name}} |
| <a name="output_proxy_uri"></a> [proxy\_uri](#output\_proxy\_uri) | The proxy endpoint that is used to access the Jupyter notebook. Only returned when the resource is in a PROVISIONED state. If needed you can utilize terraform apply -refresh-only to await the population of this value. |
| <a name="output_state"></a> [state](#output\_state) | The state of this instance. |
| <a name="output_terraform_labels"></a> [terraform\_labels](#output\_terraform\_labels) | The combination of labels configured directly on the resource and default labels configured on the provider. |
| <a name="output_update_time"></a> [update\_time](#output\_update\_time) | Instance update time. |
<!-- END_TF_DOCS -->