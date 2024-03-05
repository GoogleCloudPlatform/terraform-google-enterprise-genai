# 5-app-infra

This repo is part of a multi-part guide that shows how to configure and deploy
the example.com reference architecture described in
[Google Cloud security foundations guide](https://cloud.google.com/architecture/security-foundations). The following table lists the parts of the guide.

<table>
<tbody>
<tr>
<td><a href="../0-bootstrap">0-bootstrap</a></td>
<td>Bootstraps a Google Cloud organization, creating all the required resources
and permissions to start using the Cloud Foundation Toolkit (CFT). This
step also configures a <a href="../docs/GLOSSARY.md#foundation-cicd-pipeline">CI/CD Pipeline</a> for foundations code in subsequent
stages.</td>
</tr>
<tr>
<td><a href="../1-org">1-org</a></td>
<td>Sets up top-level shared folders, monitoring and networking projects,
organization-level logging, and baseline security settings through
organizational policies.</td>
</tr>
<tr>
<td><a href="../2-environments"><span style="white-space: nowrap;">2-environments</span></a></td>
<td>Sets up development, non-production, and production environments within the
Google Cloud organization that you've created.</td>
</tr>
<tr>
<td><a href="../3-networks-dual-svpc">3-networks-dual-svpc</a></td>
<td>Sets up base and restricted shared VPCs with default DNS, NAT (optional),
Private Service networking, VPC service controls, on-premises Dedicated
Interconnect, and baseline firewall rules for each environment. It also sets
up the global DNS hub.</td>
</tr>
<tr>
<td><a href="../3-networks-hub-and-spoke">3-networks-hub-and-spoke</a></td>
<td>Sets up base and restricted shared VPCs with all the default configuration
found on step 3-networks-dual-svpc, but here the architecture will be based on the
Hub and Spoke network model. It also sets up the global DNS hub</td>
</tr>
<tr>
<td><a href="../4-projects">4-projects</a></td>
<td>Sets up a folder structure, projects, and an application infrastructure pipeline for applications,
 which are connected as service projects to the shared VPC created in the previous stage.</td>
</tr>
<tr>
<td>5-app-infra 5-vpc-sc(this file)</td>
<td>A project folder structure which expands upon all projects created in 4-projects</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-example-foundation README](https://github.com/terraform-google-modules/terraform-example-foundation)
file.

## VPC-SC

By now, `artifact-publish` and `service-catalog` have been deployed.  The projects inflated under `6-machine-learning` are set in a service perimiter for added security.  As such, several services and accounts must be given ingress and egress policies before `6-machine-learning` has been deployed.

cd into gcp-networks

  ```bash
  cd ../gcp-networks
  ```
    
Below, you can find the values that will need to be applied to `common.auto.tfvars` and your `development.auto.tfvars`, `non-production.auto.tfvars` & `production.auto.tfvars`.

In `common.auto.tfvars` update your `perimeter_additional_members` to include:
 * the service acccount for bu3infra-pipeline: `"serviceAccount:sa-tf-cb-bu3-machine-learning@[prj-c-bu3infra-pipeline-project-id].iam.gserviceaccount.com"`
 * the service account for your cicd pipeline: `"serviceAccount:sa-terraform-env@[prj-b-seed-project-id].iam.gserviceaccount.com"`
 * your development environment logging bucket service account: `"serviceAccount:service-[prj-d-logging-project-number]@gs-project-accounts.iam.gserviceaccount.com"`
 * your development environment service acount for cloudbuild: `"serviceAccount:[prj-d-machine-learning-project-number]@cloudbuild.gserviceaccount.com"`

 In each respective environment folders, update your `development.auto.tfvars`, `non-production.auto.tfvars` & `production.auto.tfvars` to include these changes:

    ```
    ingress_policies = [
        // users
        {
            "from" = {
            "identity_type" = "ANY_IDENTITY"
            "sources" = {
                "access_level" = "accessPolicies/270868347751/accessLevels/alp_d_shared_restricted_members_556e"
            }
            },
            "to" = {
            "resources" = [
                "projects/[prj-[your-environment-shared-restricted-project-number]",
                "projects/[prj-[your-environment-kms-project-number]",
                "projects/[prj-[your-environment-bu3machine-learning-number]",
            ]
            "operations" = {
                "compute.googleapis.com" = {
                "methods" = ["*"]
                }
                "dns.googleapis.com" = {
                "methods" = ["*"]
                }
                "logging.googleapis.com" = {
                "methods" = ["*"]
                }
                "storage.googleapis.com" = {
                "methods" = ["*"]
                }
                "cloudkms.googleapis.com" = {
                "methods" = ["*"]
                }
            }
            }
        },
    ]
    ```

for your DEVELOPMENT.AUTO.TFVARS file, also include this as an egress policy:

```bash
egress_policies = [
    // notebooks
    {
        "from" = {
        "identity_type" = ""
        "identities" = [     
            "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@gcp-sa-notebooks.iam.gserviceaccount.com",   
            "serviceAccount:service-[prj-d-bu3machine-learning-project-number]@compute-system.iam.gserviceaccount.com", 
        ]
        },
        "to" = {
        "resources" = ["projects/[prj-d-kms-project-number]"]
        "operations" = {
            "compute.googleapis.com" = {
            "methods" = ["*"]
            }
            "cloudkms.googleapis.com" = {
            "methods" = ["*"]
            }
        }
        }
    },
]
```

<!-- Please note that this will cover some but not ALL the policies that will be needed.  During deployment there will be violations that will occur which come from unknown google projects outside the scope of your organization.  It will be the responsibility of the operator(s) deploying this process to view logs about the errors and make adjustments accordingly.  Most notably, this was observed for Service Catalog.  There will be an instance where an egress policy to be added for `cloudbuild.googleapis.com` access:

```bash
// Service Catalog
{
    "from" = {
    "identity_type" = "ANY_IDENTITY"
    "identities"    = []
    },
    "to" = {
    "resources" = ["projects/[some random google project id]"] 
    "operations" = {
        "cloudbuild.googleapis.com" = {
        "methods" = ["*"]
        }
    }
    }
},
``` -->