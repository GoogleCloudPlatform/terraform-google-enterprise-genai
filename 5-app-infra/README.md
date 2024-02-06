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
<td>5-app-infra (this file)</td>
<td>A project folder structure which expands upon all projects created in 4-projects</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-example-foundation README](https://github.com/terraform-google-modules/terraform-example-foundation)
file.

## Purpose

This structure is for deploying out an environment suited for Machine Learning.  You will notice in the folder `projects`, there are several other folders.
Each folder represents a project that will be _expanded_ upon.  In step 4, we have initiated the creation of these projects, enabled API's and assigned roles to various service accounts, service agents and cryptography keys that are needed for each respective project to operate successfully.  

For the purposes of this demonstration, we assume that you are using Cloud Build or manual deployment.  

When viewing each folder under `projects`, consider them as seperate repositories which will be used to deploy out each respective project.  In the case of using Cloud Build (which is what this example is primarily based on), each folder will be placed in its own GCP cloud source repository for deployment.  There is a README placed in each project folder which will highlight the necessary steps to achieve deployment.

When deploying/expanding upon each project, you will find your Cloud Build pipelines being executed in `prj-c-bu3infra-pipeline`.  

It is recommended that you _first deploy_ the `common` projects (`artifact-publish` and `service-catalog` before deploying `machine-learning`.  The order of deploying the `common` projects does not matter, however `machine-learning` should be the last project to be inflated.  

## VPC-SC

Before deploying your projects, be aware that for the purposes of this machine learning project, there are several projects in each respective environment that have been placed within a `service perimeter`.
As such, during your deployment process, you _will_ encounter deployment errors related to VPC-SC violations.  Before continuing onto `5-app-infra/projects`, you will need to go _back_ into `4-networks-dual-svpc` and _update_ 
your ingress rules.  

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
                "projects/[prj-[your-environment][shared-restricted-project-number]",
                "projects/[prj-[your-environment]-kms-project-number]",
                "projects/[prj-[your-environment]-bu3machine-learning-number]",
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

    ```
    egress_policies = [
        // notebooks
        {
            "from" = {
            "identity_type" = ""
            "identities" = [
                "serviceAccount:bq-[prj-d-bu3machine-learning-project-number]@bigquery-encryption.iam.gserviceaccount.com",     
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

Please note that this will cover some but not ALL the policies that will be needed.  During deployment there will be violations that will occur which come from unknown google projects outside the scope of your organization.  It will be the responsibility of the operator(s) deploying this process to view logs about the errors and make adjustments accordingly.  Most notably, this was observed for Service Catalog.  There will be an instance where an egress policy to be added for `cloudbuild.googleapis.com` access:

    ```
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
    ```