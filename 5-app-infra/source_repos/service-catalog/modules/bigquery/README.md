<!-- BEGIN_TF_DOCS -->
Copyright 2024 Google LLC

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
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bigquery"></a> [bigquery](#module\_bigquery) | terraform-google-modules/bigquery/google | 7.0.0 |

## Resources

| Name | Type |
|------|------|
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dataset_id"></a> [dataset\_id](#input\_dataset\_id) | A unique ID for this dataset, without the project name. The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores (\_). The maximum length is 1,024 characters. | `string` | n/a | yes |
| <a name="input_default_partition_expiration_ms"></a> [default\_partition\_expiration\_ms](#input\_default\_partition\_expiration\_ms) | The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. | `number` | `null` | no |
| <a name="input_default_table_expiration_ms"></a> [default\_table\_expiration\_ms](#input\_default\_table\_expiration\_ms) | The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. | `number` | `null` | no |
| <a name="input_delete_contents_on_destroy"></a> [delete\_contents\_on\_destroy](#input\_delete\_contents\_on\_destroy) | If true, delete all the tables in the dataset when destroying the dataset; otherwise, destroying the dataset does not affect the tables in the dataset. If you try to delete a dataset that contains tables, and you set delete\_contents\_on\_destroy to false when you created the dataset, the request will fail. Always use this flag with caution. A missing value is treated as false. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | A user-friendly description of the dataset | `string` | `""` | no |
| <a name="input_friendly_name"></a> [friendly\_name](#input\_friendly\_name) | A descriptive name for the dataset | `string` | `""` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional Project ID. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dataset\_id | A unique ID for this dataset, without the project name. The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores (\_). The maximum length is 1,024 characters. | `string` | n/a | yes |
| default\_partition\_expiration\_ms | The default partition expiration for all partitioned tables in the dataset, in milliseconds. Once this property is set, all newly-created partitioned tables in the dataset will have an expirationMs property in the timePartitioning settings set to this value, and changing the value will only affect new tables, not existing ones. The storage in a partition will have an expiration time of its partition time plus this value. | `number` | `null` | no |
| default\_table\_expiration\_ms | The default lifetime of all tables in the dataset, in milliseconds. The minimum value is 3600000 milliseconds (one hour). Once this property is set, all newly-created tables in the dataset will have an expirationTime property set to the creation time plus the value in this property, and changing the value will only affect new tables, not existing ones. When the expirationTime for a given table is reached, that table will be deleted automatically. If a table's expirationTime is modified or removed before the table expires, or if you provide an explicit expirationTime when creating a table, that value takes precedence over the default expiration time indicated by this property. | `number` | `null` | no |
| delete\_contents\_on\_destroy | If true, delete all the tables in the dataset when destroying the dataset; otherwise, destroying the dataset does not affect the tables in the dataset. If you try to delete a dataset that contains tables, and you set delete\_contents\_on\_destroy to false when you created the dataset, the request will fail. Always use this flag with caution. A missing value is treated as false. | `bool` | `false` | no |
| description | A user-friendly description of the dataset. | `string` | `""` | no |
| friendly\_name | A descriptive name for the dataset. | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
