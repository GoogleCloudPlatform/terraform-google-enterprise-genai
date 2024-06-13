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
<td>5-app-infra 02-artifact-publish-repo(this file)</td>
<td>Configures a cloud build repository for Docker builds</td>
</tr>
</tbody>
</table>

For an overview of the architecture and the parts, see the
[terraform-google-enterprise-genai README](https://github.com/terraform-google-modules/terraform-google-enterprise-genai)
file.

## Usage

**Note:** If you are using MacOS, replace `cp -RT` with `cp -R` in the relevant
commands. The `-T` flag is needed for Linux, but causes problems for MacOS.

### Deploying with Cloud Build

1. Grab the Artifact Project ID
   ```shell
   export ARTIFACT_PROJECT_ID=$(terraform -chdir="gcp-projects/business_unit_3/shared" output -raw common_artifacts_project_id)
   echo ${ARTIFACT_PROJECT_ID}
   ```

1. Clone the freshly minted Cloud Source Repository that was created for this project.
   ```shell
   gcloud source repos clone publish-artifacts --project=${ARTIFACT_PROJECT_ID}
   ```
1. Enter the repo folder and copy over the artifact files from `5-app-infra/2-artifact-publish-repo` folder.
   ```shell
   cd publish-artifacts
   git commit -m "Initialize Repository" --allow-empty
   cp -RT ../ml-foundations/5-app-infra/2-artifact-publish-repo/ .
   ```
1. Commit changes and push your main branch to the new repo.
   ```shell
   git add .
   git commit -m 'Build Images'

   git push --set-upstream origin main
   ```
1. Navigate to the project that was output from `${ARTIFACT_PROJECT_ID}` in Google's Cloud Console to view the first run of images being built.
