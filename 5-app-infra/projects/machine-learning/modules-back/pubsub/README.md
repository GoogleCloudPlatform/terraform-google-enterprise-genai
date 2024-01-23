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
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_project_service_identity.agent](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google-beta_google_pubsub_topic.pubsub_topic](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_pubsub_topic) | resource |
| [google_kms_crypto_key_iam_member.kms-key-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [time_sleep.wait_30_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
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
| <a name="output_id"></a> [id](#output\_id) | an identifier for the resource with format projects/{{project}}/topics/{{name}} |
<!-- END_TF_DOCS -->

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys for Pub/Sub Messages| PS-CO-6.1| SC-12 <br />SC-13| PR.DS-1.1 <br />PR.DS-1.2<br /> PR.DS-2.1 <br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
|Configure Message Storage Policies | PS-CO-4.1 | AC-3 <br /> AC-17 <br /> AC-20 <br />| PR.AC-3.1 <br />PR.AC-3.2<br />  PR.AC-4.1 <br /> PR.AC-4.2 <br /> PR.AC-4.3 <br /> PR.AC-6.1 <br /> PR.PT-3.1 <br /> PR.PT-4.1 | Optional | ML Foundation v0.1.0-alpha.1