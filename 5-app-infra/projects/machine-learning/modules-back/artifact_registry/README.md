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
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_artifact_registry_repository.registry](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_artifact_registry_repository) | resource |
| [google-beta_google_project_service_identity.artifact_registry](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google_kms_crypto_key_iam_member.kms-key-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [time_sleep.wait_30_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
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

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys| COM-CO-2.3| SC-12 <br />SC-13| PR.DS-1.1 <br />PR.DS-2.1<br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
|Clean Up Policy | AR-CO-6.1 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
