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
| [google-beta_google_pubsub_topic.pubsub_topic](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_pubsub_topic) | resource |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_locked_regions"></a> [locked\_regions](#input\_locked\_regions) | Regions that pubsub presistence is locked to | `list(any)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| <a name="input_message_retention_duration"></a> [message\_retention\_duration](#input\_message\_retention\_duration) | Message retention duration. | `string` | `"86400s"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional Project ID. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| <a name="input_topic_name"></a> [topic\_name](#input\_topic\_name) | Topic name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pubsub_topic"></a> [pubsub\_topic](#output\_pubsub\_topic) | Pub/Sub Topic. |
<!-- END_TF_DOCS -->

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys for Pub/Sub Messages| PS-CO-6.1| SC-12 <br />SC-13| PR.DS-1.1 <br />PR.DS-1.2<br /> PR.DS-2.1 <br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
|Configure Message Storage Policies | PS-CO-4.1 | AC-3 <br /> AC-17 <br /> AC-20 <br />| PR.AC-3.1 <br />PR.AC-3.2<br />  PR.AC-4.1 <br /> PR.AC-4.2 <br /> PR.AC-4.3 <br /> PR.AC-6.1 <br /> PR.PT-3.1 <br /> PR.PT-4.1 | Optional | ML Foundation v0.1.0-alpha.1
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kms\_key\_name | The KMS key to be used on the keyring, if not specified will use the default key created in 4-projects step" | `string` | `""` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| locked\_regions | Regions that Pub/Sub persistence is locked to. | `list(any)` | <pre>[<br>  "us-central1",<br>  "us-east4"<br>]</pre> | no |
| message\_retention\_duration | Message retention duration. | `string` | `"86400s"` | no |
| project\_id | Project ID. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| topic\_name | Topic name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| pubsub\_topic | Pub/Sub Topic. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
