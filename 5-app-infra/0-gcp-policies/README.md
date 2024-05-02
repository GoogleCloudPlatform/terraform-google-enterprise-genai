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
<td>5-app-infra - 01-gcp-polcies(this file)</td>
<td>Configures GCP Policies repository for Cloud Build</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-example-foundation README](https://github.com/terraform-google-modules/terraform-example-foundation)
file.

## Purpose

When using Cloud Build for deployment, Policy Verification must be checked.  This procedure will configure a gcp-policy repository that will be used in subsequent deployments in `5-app-infra`

### Deploying with Cloud Build

1. Ensure you are in a neutral directory outside any other git related repositories.

1. Clone the `gcp-policies` repo based on the Terraform output from the `0-bootstrap` step.
Clone the repo at the same level of the `terraform-example-foundation` folder, the following instructions assume this layout.
Run `terraform output cloudbuild_project_id` in the `0-bootstrap` folder to get the Cloud Build Project ID.

   ```bash
   export INFRA_PIPELINE_PROJECT_ID=$(terraform -chdir="gcp-projects/business_unit_3/shared/" output -raw cloudbuild_project_id)
   echo ${INFRA_PIPELINE_PROJECT_ID}

   gcloud source repos clone gcp-policies gcp-policies-app-infra --project=${INFRA_PIPELINE_PROJECT_ID}
   ```

   **Note:** `gcp-policies` repo has the same name as the repo created in step `1-org`. In order to prevent a collision, the previous command will clone this repo in the folder `gcp-policies-app-infra`.

1. Commit changes and push your main branch to the new repo.

   ```bash
   git add .
   git commit -m 'Initialize policy library repo'

   git push --set-upstream origin main
   ```

1. Navigate out of the repo.

   ```bash
   cd ..
   ```
