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
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_artifact_registry_repository.registry](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_repository) | resource |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cleanup_policies"></a> [cleanup\_policies](#input\_cleanup\_policies) | List of cleanup policies. | <pre>list(object({<br>    id     = string<br>    action = optional(string)<br>    condition = optional(list(object({<br>      tag_state             = optional(string)<br>      tag_prefixes          = optional(list(string))<br>      package_name_prefixes = optional(list(string))<br>      older_than            = optional(string)<br>    })))<br>    most_recent_versions = optional(list(object({<br>      package_name_prefixes = optional(list(string))<br>      keep_count            = optional(number)<br>    })))<br>  }))</pre> | <pre>[<br>  {<br>    "action": "DELETE",<br>    "condition": [<br>      {<br>        "older_than": "2592000s",<br>        "tag_prefixes": [<br>          "alpha",<br>          "v0"<br>        ],<br>        "tag_state": "TAGGED"<br>      }<br>    ],<br>    "id": "delete-prerelease"<br>  }<br>]</pre> | no |
| <a name="input_cleanup_policy_dry_run"></a> [cleanup\_policy\_dry\_run](#input\_cleanup\_policy\_dry\_run) | Whether to perform a dry run of the cleanup policy. | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the repository. | `string` | `""` | no |
| <a name="input_format"></a> [format](#input\_format) | Format of the repository. | `string` | `"DOCKER"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the repository. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional Project ID. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cleanup\_policies | List of cleanup policies. | <pre>list(object({<br>    id     = string<br>    action = optional(string)<br>    condition = optional(list(object({<br>      tag_state             = optional(string)<br>      tag_prefixes          = optional(list(string))<br>      package_name_prefixes = optional(list(string))<br>      older_than            = optional(string)<br>    })))<br>    most_recent_versions = optional(list(object({<br>      package_name_prefixes = optional(list(string))<br>      keep_count            = optional(number)<br>    })))<br>  }))</pre> | <pre>[<br>  {<br>    "action": "DELETE",<br>    "condition": [<br>      {<br>        "older_than": "2592000s",<br>        "tag_prefixes": [<br>          "alpha",<br>          "v0"<br>        ],<br>        "tag_state": "TAGGED"<br>      }<br>    ],<br>    "id": "delete-prerelease"<br>  }<br>]</pre> | no |
| cleanup\_policy\_dry\_run | Whether to perform a dry run of the cleanup policy. | `bool` | `false` | no |
| description | Description of the repository. | `string` | `""` | no |
| format | Format of the repository. | `string` | `"DOCKER"` | no |
| kms\_key\_name | The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step" | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| name | Name of the repository. | `string` | n/a | yes |
| project\_id | Project ID. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
