## IAM Permission Requirements

To execute the provided Terraform configuration the following IAM permissions are required:

- `cloudkms.cryptoKeys.get`
- `cloudkms.cryptoKeys.setIamPolicy`
- `iam.serviceAccounts.create`
- `iam.serviceAccounts.update`
- `storage.hmacKeys.create`
- `storage.hmacKeys.get`
- `storage.buckets.create`
- `storage.buckets.get`
- `storage.buckets.update`
- `storage.buckets.setIamPolicy`
- `storage.buckets.setLifecycle`
- `storage.objects.create`
- `storage.objects.delete`
- `resourcemanager.projects.get`

## Notes:
- Additional permissions may be required based on specific use cases and actions within these resources.
- It's recommended to adhere to the principle of least privilege and grant only the permissions necessary for the tasks.
- Assign these permissions via predefined roles or create a custom IAM role encompassing all necessary permissions.
- Always review and adjust permissions according to organizational security policies.


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
| [google-beta_google_storage_bucket.bucket](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_storage_bucket) | resource |
| [google_storage_bucket_object.root_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_kms_crypto_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_crypto_key) | data source |
| [google_kms_key_ring.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/kms_key_ring) | data source |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_projects.kms](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |
| [google_projects.log](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_random_suffix"></a> [add\_random\_suffix](#input\_add\_random\_suffix) | whether to add a random suffix to the bucket name | `bool` | `false` | no |
| <a name="input_dual_region_locations"></a> [dual\_region\_locations](#input\_dual\_region\_locations) | dual region description | `list(string)` | `[]` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | (Optional, Default: true) When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run. | `bool` | `true` | no |
| <a name="input_gcs_bucket_prefix"></a> [gcs\_bucket\_prefix](#input\_gcs\_bucket\_prefix) | Name prefix to be used for GCS Bucket | `string` | `"bkt"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to be attached to the buckets | `map(string)` | <pre>{<br>  "classification": "dataclassification",<br>  "label": "samplelabel",<br>  "owner": "testowner"<br>}</pre> | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches\_storage\_class should be a comma delimited string. | <pre>set(object({<br>    # Object with keys:<br>    # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.<br>    # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.<br>    action = map(string)<br><br>    # Object with keys:<br>    # - age - (Optional) Minimum age of an object in days to satisfy this condition.<br>    # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.<br>    # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".<br>    # - matches_storage_class - (Optional) Comma delimited string for storage class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL.<br>    # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.<br>    # - custom_time_before - (Optional) A date in the RFC 3339 format YYYY-MM-DD. This condition is satisfied when the customTime metadata for the object is set to an earlier date than the date used in this lifecycle condition.<br>    # - days_since_custom_time - (Optional) The number of days from the Custom-Time metadata attribute after which this condition becomes true.<br>    # - days_since_noncurrent_time - (Optional) Relevant only for versioned objects. Number of days elapsed since the noncurrent timestamp of an object.<br>    # - noncurrent_time_before - (Optional) Relevant only for versioned objects. The date in RFC 3339 (e.g. 2017-06-13) when the object became nonconcurrent.<br>    condition = map(string)<br>  }))</pre> | <pre>[<br>  {<br>    "action": {<br>      "storage_class": "NEARLINE",<br>      "type": "SetStorageClass"<br>    },<br>    "condition": {<br>      "age": "30",<br>      "matches_storage_class": "REGIONAL"<br>    }<br>  },<br>  {<br>    "action": {<br>      "type": "Delete"<br>    },<br>    "condition": {<br>      "with_state": "ARCHIVED"<br>    }<br>  }<br>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | name of bucket | `string` | n/a | yes |
| <a name="input_object_folder_temporary_hold"></a> [object\_folder\_temporary\_hold](#input\_object\_folder\_temporary\_hold) | Set root folder temporary hold according to security control GCS-CO-6.16, toggle off to allow for object deletion. | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Optional Project ID. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| <a name="input_requester_pays"></a> [requester\_pays](#input\_requester\_pays) | Enables Requester Pays on a storage bucket. | `bool` | `false` | no |
| <a name="input_retention_policy"></a> [retention\_policy](#input\_retention\_policy) | Map of retention policy values. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket#retention_policy | `any` | `{}` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Storage class to create the bucket | `string` | `"STANDARD"` | no |
| <a name="input_uniform_bucket_level_access"></a> [uniform\_bucket\_level\_access](#input\_uniform\_bucket\_level\_access) | Whether to have uniform access levels or not | `bool` | `true` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Whether to enable versioning or not | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_storage_bucket"></a> [storage\_bucket](#output\_storage\_bucket) | Storage Bucket. |
<!-- END_TF_DOCS -->

## Security Controls

The following table outlines which of the suggested controls for Vertex Generative AI are enabled in this module.
| Name | Control ID | NIST 800-53 | CRI Profile | Category | Source Blueprint
|------|------------|-------------|-------------|----------| ----------------|
|Customer Managed Encryption Keys| COM-CO-2.3| SC-12 <br />SC-13| PR.DS-1.1 <br />PR.DS-2.1<br /> PR.DS-2.2 <br /> PR.DS-5.1 | Recommended | Secure Foundation v4
|Regional Storage Class Lifecycle Rule | GCS-CO-6.11 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Regional Storage Class Lifecycle Rule | GCS-CO-6.12 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Ensure Lifecycle management is enabled 1 of 2 | GCS-CO-6.13 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Ensure Lifecycle management is enabled 2 of 2 | GCS-CO-6.14 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Ensure Retention policy is using the bucket lock| GCS-CO-6.15 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Object contains a temporary hold and should be evaluated| GCS-CO-6.16 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Retention Policy| GCS-CO-6.17 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Classification Tag| GCS-CO-6.18 | SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Versioning is Enabled| GCS-CO-6.2| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Log Bucket Exists| GCS-CO-6.3| AU-2<br /> AU-3<br /> AU-8<br /> AU-9| DM.ED-7.1 <br />DM.ED-7.2<br />DM.ED-7.3<br />DM.ED-7.4<br />PR.IP-1.4 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Labeling Tag| GCS-CO-6.4| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Deletion Rules| GCS-CO-6.5| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Deletion Rules For Deleted Objects| GCS-CO-6.6| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Ensure that versioning is enabled on all Cloud Storage instances| GCS-CO-6.7| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Owner Tag| GCS-CO-6.8| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1
|Ensure HMAC keys for service accounts are handled correctly| GCS-CO-6.9| SI-12 <br /> SC-13 | PR.IP-1.1 <br />PR.IP-1.2<br />  PR.IP-2.1<br /> PR.DS-2.2 <br /> PR.DS-5.1 | Required | ML Foundation v0.1.0-alpha.1
|Owner Tag| GCS-CO-7.1| SI-12 | PR.IP-2.1 <br />PR.IP-2.2<br />  PR.IP-2.3 | Recommended based on customer use case | ML Foundation v0.1.0-alpha.1


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| add\_random\_suffix | Whether to add a random suffix to the bucket name. | `bool` | `false` | no |
| dual\_region\_locations | Dual region description. | `list(string)` | `[]` | no |
| force\_destroy | (Optional, Default: true) When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run. | `bool` | `true` | no |
| gcs\_bucket\_prefix | Name prefix to be used for GCS Bucket. | `string` | `"bkt"` | no |
| kms\_keyring | The KMS keyring that will be used when selecting the KMS key, preferably this should be on the same region as the other resources and the same environment.<br>This value can be obtained by running "gcloud kms keyrings list --project=KMS\_PROJECT\_ID --location=REGION." | `string` | n/a | yes |
| labels | Labels to be attached to the buckets. | `map(string)` | <pre>{<br>  "classification": "dataclassification",<br>  "label": "samplelabel",<br>  "owner": "testowner"<br>}</pre> | no |
| lifecycle\_rules | List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches\_storage\_class should be a comma delimited string. | <pre>set(object({<br>    # Object with keys:<br>    # - type - The type of the action of this Lifecycle Rule. Supported values: Delete and SetStorageClass.<br>    # - storage_class - (Required if action type is SetStorageClass) The target Storage Class of objects affected by this Lifecycle Rule.<br>    action = map(string)<br><br>    # Object with keys:<br>    # - age - (Optional) Minimum age of an object in days to satisfy this condition.<br>    # - created_before - (Optional) Creation date of an object in RFC 3339 (e.g. 2017-06-13) to satisfy this condition.<br>    # - with_state - (Optional) Match to live and/or archived objects. Supported values include: "LIVE", "ARCHIVED", "ANY".<br>    # - matches_storage_class - (Optional) Comma delimited string for storage class of objects to satisfy this condition. Supported values include: MULTI_REGIONAL, REGIONAL.<br>    # - num_newer_versions - (Optional) Relevant only for versioned objects. The number of newer versions of an object to satisfy this condition.<br>    # - custom_time_before - (Optional) A date in the RFC 3339 format YYYY-MM-DD. This condition is satisfied when the customTime metadata for the object is set to an earlier date than the date used in this lifecycle condition.<br>    # - days_since_custom_time - (Optional) The number of days from the Custom-Time metadata attribute after which this condition becomes true.<br>    # - days_since_noncurrent_time - (Optional) Relevant only for versioned objects. Number of days elapsed since the noncurrent timestamp of an object.<br>    # - noncurrent_time_before - (Optional) Relevant only for versioned objects. The date in RFC 3339 (e.g. 2017-06-13) when the object became nonconcurrent.<br>    condition = map(string)<br>  }))</pre> | <pre>[<br>  {<br>    "action": {<br>      "storage_class": "NEARLINE",<br>      "type": "SetStorageClass"<br>    },<br>    "condition": {<br>      "age": "30",<br>      "matches_storage_class": "REGIONAL"<br>    }<br>  },<br>  {<br>    "action": {<br>      "type": "Delete"<br>    },<br>    "condition": {<br>      "with_state": "ARCHIVED"<br>    }<br>  }<br>]</pre> | no |
| log\_bucket | Bucket to store logs from the created bucket. This is the Env-level Log Bucket creted on 2-environments. | `string` | n/a | yes |
| name | Name of bucket. | `string` | n/a | yes |
| object\_folder\_temporary\_hold | Set root folder temporary hold according to security control GCS-CO-6.16, toggle off to allow for object deletion. | `bool` | `false` | no |
| project\_id | Project ID to create resources. | `string` | n/a | yes |
| region | The resource region, one of [us-central1, us-east4]. | `string` | `"us-central1"` | no |
| requester\_pays | Enables Requester Pays on a storage bucket. | `bool` | `false` | no |
| retention\_policy | Map of retention policy values. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket#retention_policy. | `any` | `{}` | no |
| storage\_class | Storage class to create the bucket. | `string` | `"STANDARD"` | no |
| uniform\_bucket\_level\_access | Whether to have uniform access levels or not. | `bool` | `true` | no |
| versioning\_enabled | Whether to enable versioning or not. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| storage\_bucket | Storage Bucket. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

