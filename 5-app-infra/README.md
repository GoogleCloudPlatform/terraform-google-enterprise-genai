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

