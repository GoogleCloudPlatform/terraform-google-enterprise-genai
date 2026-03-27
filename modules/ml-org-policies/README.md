# Machine Learning Organization Policies

This module configure [Organization Policies](https://cloud.google.com/resource-manager/docs/organization-policy/overview) useful for Machine Learning projects.

## Organization Policies configured in this module

- Disable file downloads on new Vertex AI Workbench instances (`constraints/ainotebooks.disableFileDownloads`)
- Disable root access on new Vertex AI Workbench user-managed notebooks and instances (`ainotebooks.disableRootAccess`)
- Disable terminal on new Vertex AI Workbench instances (`constraints/ainotebooks.disableTerminal`)
- Restrict public IP access on new Vertex AI Workbench notebooks and instances (`constraints/ainotebooks.restrictPublicIp`)
- Require automatic scheduled upgrades on new Vertex AI Workbench user-managed notebooks and instances (`constraints/ainotebooks.requireAutoUpgradeSchedule`)
- Require VPC Connector (Cloud Functions) (`constraints/cloudfunctions.requireVPCConnector`)
- Allowed Integrations (Cloud Build), controls which external services can invoke build triggers (`constraints/cloudbuild.allowedIntegrations`)
- Restrict TLS Versions (`constraints/gcp.restrictTLSVersion`)
- Restrict which projects may supply KMS CryptoKeys for CMEK (`constraints/gcp.restrictCmekCryptoKeyProjects`)
- Restrict which services may create resources without CMEK (`constraints/gcp.restrictNonCmekServices`)
- Restrict Resource Service Usage (`constraints/gcp.restrictServiceUsage`)
- Google Cloud Platform - Resource Location Restriction (`constraints/gcp.resourceLocations`)
- Restrict VM IP Forwarding (`constraints/compute.vmCanIpForward`)
- Define access mode for Vertex AI Workbench notebooks and instances (`constraints/ainotebooks.accessMode`)
- Restrict environment options on new Vertex AI Workbench notebooks and instances (`constraints/ainotebooks.environmentOptions`)
- Restrict VPC networks on new Vertex AI Workbench instances (`constraints/ainotebooks.restrictVpcNetworks`)

## References

- [Predefined posture for secure AI, essentials](https://cloud.google.com/security-command-center/docs/security-posture-essentials-secure-ai-template)
- [Predefined posture for secure AI, extended](https://cloud.google.com/security-command-center/docs/security-posture-extended-secure-ai-template)

## Usage

```hcl
module "ml_organization_policies" {
  source = "../../modules/ml-org-policies"

  org_id    = <ORGANIZATION-ID>
  folder_id = <FOLDER-ID>

  allowed_locations = [
    "us-locations"
  ]

  allowed_vertex_vpc_networks = {
    parent_type = "project"
    parent_ids  = [PROJECT-ID1,PROJECT-ID2,...],
  }
}
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_integrations | Allowed Integrations (Cloud Build) Organization Policy.<br>  Defines the allowed Cloud Build integrations for performing Builds through receiving webhooks from services outside Google Cloud. | `list(string)` | <pre>[<br>  "github.com",<br>  "source.developers.google.com"<br>]</pre> | no |
| allowed\_locations | Google Cloud Platform - Resource Location Restriction Organization Policy.<br>  Defines the set of locations where location-based Google Cloud resources can be created.<br>  See https://cloud.google.com/resource-manager/docs/organization-policy/defining-locations#location_types<br>  for information regarding entries format. | `list(string)` | <pre>[<br>  "in:us-locations"<br>]</pre> | no |
| allowed\_vertex\_access\_modes | Define access mode for Vertex AI Workbench notebooks and instances Organization Policy.<br>  Defines the modes of access allowed to Vertex AI Workbench notebooks and instances. | `list(string)` | <pre>[<br>  "single-user",<br>  "service-account"<br>]</pre> | no |
| allowed\_vertex\_images | Restrict environment options on new Vertex AI Workbench notebooks and instances Organization Policy.<br>  This list defines the VM and container image options that can be select when creating new Vertex AI Workbench notebooks and instances.<br>  Format for VM instances is "ainotebooks-vm/PROJECT\_ID/IMAGE\_TYPE/CONSTRAINED\_VALUE". Replace IMAGE\_TYPE with image-family or image-name. | `list(string)` | <pre>[<br>  "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",<br>  "ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",<br>  "ainotebooks-vm/deeplearning-platform-release/image-family/common-cu113-notebooks",<br>  "ainotebooks-vm/deeplearning-platform-release/image-family/common-cpu-notebooks",<br>  "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py310",<br>  "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py37",<br>  "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu110.py310",<br>  "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-cpu.2-12.py310",<br>  "ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-gpu.2-12.py310"<br>]</pre> | no |
| allowed\_vertex\_vpc\_networks | Restrict VPC networks on new Vertex AI Workbench instances Organization Policy.<br>  This list defines the parent resources IDs that contains the VPC networks or VPC networks themselves<br>  that a user can select when creating new Vertex AI Workbench instances.<br>  VPC network resource format id `projects/PROJECT_ID/global/networks/NETWORK_NAME`.<br>  - parent\_type: one of organization, folder, project, or network.<br>  - ids: list of IDs of organization, folder, project or network full names. | <pre>object({<br>    parent_type = string<br>    ids         = list(string)<br>  })</pre> | n/a | yes |
| folder\_id | Optional - Setting the folder\_id will place all the organization policies on the provided folder instead of the root organization. The value is the numeric folder ID. The folder must already exist. | `string` | `""` | no |
| org\_id | GCP Organization ID | `string` | n/a | yes |
| restricted\_non\_cmek\_services | Restrict which services may create resources without CMEK Organization Policy.<br>  Defines which services require Customer-Managed Encryption Keys (CMEK).<br>  Requires that, for the specified services, newly created resources must be protected by a CMEK key. | `list(string)` | <pre>[<br>  "bigquery.googleapis.com",<br>  "aiplatform.googleapis.com"<br>]</pre> | no |
| restricted\_services | Restrict Resource Service Usage Organization Policy.<br>  Defines the set of Google Cloud resource services that cannot be used within an organization or folder. | `list(string)` | <pre>[<br>  "alloydb.googleapis.com"<br>]</pre> | no |
| restricted\_tls\_versions | Restrict TLS Versions Organization Policy.<br>  Defines the set of TLS versions that cannot be used on the organization, folder, or project<br>  where this constraint is enforced, or any of that resource's children in the resource hierarchy. | `list(string)` | <pre>[<br>  "TLS_VERSION_1",<br>  "TLS_VERSION_1_1"<br>]</pre> | no |

## Outputs

No outputs.

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
