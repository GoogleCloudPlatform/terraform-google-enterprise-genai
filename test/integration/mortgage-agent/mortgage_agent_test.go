// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package mortgage_agent

import (
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestMortgageAgentInfra(t *testing.T) {

	temp := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
	)

	random := temp.GetTFSetupStringOutput("random")
	dns_zone_domain := temp.GetTFSetupStringOutput("dns_zone_domain")

	vars := map[string]interface{}{
		"kms_prevent_destroy":  false,
		"bucket_force_destroy": true,
		"mcp_internal_dns_zone": map[string]interface{}{
			"name":   "mcp-server-internal",
			"domain": "mcp." + dns_zone_domain,
		},
		"mcp_services": map[string]interface{}{
			"legacy-dms": map[string]interface{}{
				"image":              "us-docker.pkg.dev/cloudrun/container/placeholder",
				"min_instance_count": 1,
			},
			"corporate-email": map[string]interface{}{
				"image":              "us-docker.pkg.dev/cloudrun/container/placeholder",
				"min_instance_count": 1,
			},
			"income-verification": map[string]interface{}{
				"image":              "us-docker.pkg.dev/cloudrun/container/placeholder",
				"min_instance_count": 1,
			},
		},
		"mcp_tool_specs": map[string]interface{}{
			"legacy-dms":          "src/legacy-dms/toolspec.json",
			"corporate-email":     "src/corporate-email/toolspec.json",
			"income-verification": "src/income-verification-api/toolspec.json",
		},
		"agent_gateway_iap_iam_enforcement_mode": "DRY_RUN",
		"enable_model_armor":                     false, // Set to true only when using a real domain with certificate
		"enable_model_armor_mcp_floor_setting":   false,
		"model_armor_request_template_id":        "agw-req-" + random,
		"model_armor_response_template_id":       "agw-resp-" + random,
		"model_armor_inspect_template_id":        "agw-insp-" + random,
		"model_armor_deidentify_template_id":     "agw-deid-" + random,
	}

	mortgage := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 5*time.Minute),
		tft.WithVars(vars),
	)

	mortgage.DefineVerify(func(a *assert.Assertions) {
		mortgage.DefaultVerify(a)

		terraformSA := mortgage.GetStringOutput("terraform_service_account")
		projectID := mortgage.GetStringOutput("project_id")
		region := mortgage.GetStringOutput("region")

		// Cloud Storage
		cloudbuildBucket := mortgage.GetStringOutput("cloudbuild_bucket")
		gcloudAlphaOpts := gcloud.WithCommonArgs([]string{"--project", projectID, "--impersonate-service-account", terraformSA, "--json"})
		bkt := gcloud.Run(t, fmt.Sprintf("alpha storage ls --buckets gs://%s", cloudbuildBucket), gcloudAlphaOpts).Array()[0]
		a.Equal(cloudbuildBucket, bkt.Get("metadata.id").String(), fmt.Sprintf("Bucket %s should exist", cloudbuildBucket))

		// Networking (VPC, Subnet e PSC Subnet)
		vpcName := mortgage.GetStringOutput("vpc_name")
		networkSelfLink := mortgage.GetStringOutput("network_self_link")
		network := gcloud.Runf(t, "compute networks describe %s --project %s --impersonate-service-account %s", vpcName, projectID, terraformSA)
		a.Equal(vpcName, network.Get("name").String(), "VPC network should exist")
		a.Equal(networkSelfLink, network.Get("selfLink").String(), "VPC network selfLink should match")

		subnetName := mortgage.GetStringOutput("subnet_name")
		subnetSelfLink := mortgage.GetStringOutput("subnet_self_link")
		subnet := gcloud.Runf(t, "compute networks subnets describe %s --region %s --project %s --impersonate-service-account %s", subnetName, region, projectID, terraformSA)
		a.Equal(subnetName, subnet.Get("name").String(), "Primary subnet should exist")
		a.Equal(subnetSelfLink, subnet.Get("selfLink").String(), "Primary subnet selfLink should match")

		pscSubnetSelfLink := mortgage.GetStringOutput("psc_subnet_self_link")
		pscSubnetName := testutils.GetLastSplitElement(pscSubnetSelfLink, "/")
		pscSubnet := gcloud.Runf(t, "compute networks subnets describe %s --region %s --project %s --impersonate-service-account %s", pscSubnetName, region, projectID, terraformSA)
		a.Equal(pscSubnetName, pscSubnet.Get("name").String(), "PSC Subnet should exist")
		a.Contains(pscSubnet.Get("selfLink").String(), mortgage.GetStringOutput("psc_subnet_id"), "PSC Subnet selfLink should match the Terraform ID")
		a.Equal("PRIVATE_SERVICE_CONNECT", pscSubnet.Get("purpose").String(), "Subnet purpose should be PRIVATE_SERVICE_CONNECT")

		// Cloud Run (MCP Services) & IAM
		mcpServiceNames := terraform.OutputMap(t, mortgage.GetTFOptions(), "mcp_service_names")
		mcpServiceURLs := terraform.OutputMap(t, mortgage.GetTFOptions(), "mcp_service_urls")
		mcpServiceAccounts := terraform.OutputMap(t, mortgage.GetTFOptions(), "mcp_service_account_emails")
		agentInvokerEmail := mortgage.GetStringOutput("agent_mcp_invoker_email")
		expectedIngress := mortgage.GetStringOutput("mcp_cloud_run_ingress_annotation")

		// Invoker SA
		invokerSA := gcloud.Runf(t, "iam service-accounts describe %s --project %s --impersonate-service-account %s", agentInvokerEmail, projectID, terraformSA)
		a.Equal(agentInvokerEmail, invokerSA.Get("email").String(), "Agent MCP Invoker SA should exist")

		// Runtime SAs dos MCPs
		for key, svcName := range mcpServiceNames {
			saEmail := mcpServiceAccounts[key]
			sa := gcloud.Runf(t, "iam service-accounts describe %s --project %s --impersonate-service-account %s", saEmail, projectID, terraformSA)
			a.Equal(saEmail, sa.Get("email").String(), fmt.Sprintf("MCP %s Runtime SA should exist", key))

			svc := gcloud.Runf(t, "run services describe %s --region %s --project %s --impersonate-service-account %s", svcName, region, projectID, terraformSA)
			a.Equal(svcName, svc.Get("metadata.name").String(), fmt.Sprintf("MCP service %s should exist", svcName))
			a.True(svc.Get("status.conditions.#(type==\"Ready\").status").String() == "True", fmt.Sprintf("Service %s must be Ready", svcName))
			a.Equal(expectedIngress, svc.Get("metadata.annotations.run\\.googleapis\\.com/ingress").String(), "Ingress annotation should match")

			if expectedURL, ok := mcpServiceURLs[key]; ok {
				a.Equal(expectedURL, svc.Get("status.url").String(), fmt.Sprintf("Service %s URL should match", svcName))
			}

			iamPolicy := gcloud.Runf(t, "run services get-iam-policy %s --region %s --project %s --impersonate-service-account %s", svcName, region, projectID, terraformSA)
			members := utils.GetResultStrSlice(iamPolicy.Get("bindings.#(role==\"roles/run.invoker\").members").Array())
			a.Contains(members, fmt.Sprintf("serviceAccount:%s", agentInvokerEmail), fmt.Sprintf("Invoker SA must have run.invoker role on %s", svcName))
		}

		// Cloud DNS & Internal LB IP
		lbIP := mortgage.GetStringOutput("mcp_internal_lb_ip")
		a.NotEmpty(lbIP, "MCP Internal LB IP should not be empty")

		mcpDNSZone := mortgage.GetStringOutput("mcp_internal_dns_zone_name")
		z := gcloud.Runf(t, "dns managed-zones describe %s --project %s --impersonate-service-account %s", mcpDNSZone, projectID, terraformSA)
		a.Equal(mcpDNSZone, z.Get("name").String(), "MCP Internal DNS Zone should exist")
		a.Equal(mortgage.GetStringOutput("mcp_internal_dns_domain"), z.Get("dnsName").String(), "MCP Internal DNS domain should match")
		a.Equal("private", z.Get("visibility").String(), "MCP DNS Zone visibility should be private")

		// PSC Interface (Network Attachment)
		pscAttName := mortgage.GetStringOutput("psc_interface_network_attachment_name")
		pscAttId := mortgage.GetStringOutput("psc_interface_network_attachment_id")

		att := gcloud.Runf(t, "compute network-attachments describe %s --region %s --project %s --impersonate-service-account %s", pscAttName, region, projectID, terraformSA)
		a.Equal(pscAttName, att.Get("name").String(), "PSC Interface Network Attachment should exist")
		a.Contains(att.Get("selfLink").String(), pscAttId, "PSC Attachment selfLink should match the Terraform ID")

		// Artifact Registry
		registryID := mortgage.GetStringOutput("artifact_registry_id")
		repoName := testutils.GetLastSplitElement(registryID, "/")
		repo := gcloud.Runf(t, "artifacts repositories describe %s --location %s --project %s --impersonate-service-account %s", repoName, region, projectID, terraformSA)
		a.Equal(repoName, testutils.GetLastSplitElement(repo.Get("name").String(), "/"), "Artifact Registry should exist")
		a.Equal("DOCKER", repo.Get("format").String(), "Artifact Registry format should be DOCKER")

		// Certificates
		certName := mortgage.GetStringOutput("regional_certificate_name")
		cleanCertName := testutils.GetLastSplitElement(certName, "/")
		cert := gcloud.Runf(t, "certificate-manager certificates describe %s --location %s --project %s --impersonate-service-account %s", cleanCertName, region, projectID, terraformSA)
		a.Equal(cleanCertName, testutils.GetLastSplitElement(cert.Get("name").String(), "/"), "Certificate should exist")

		// Agent Gateway & Registry Endpoints
		agentGatewayID := mortgage.GetStringOutput("agent_gateway_id")
		mtlsEndpoint := mortgage.GetStringOutput("agent_gateway_mtls_endpoint")
		registryURI := mortgage.GetStringOutput("agent_gateway_registry_uri")

		a.NotEmpty(agentGatewayID, "Agent Gateway ID should not be empty")
		a.NotEmpty(mtlsEndpoint, "Agent Gateway mTLS endpoint should not be empty")
		a.NotEmpty(registryURI, "Agent Gateway registry URI should not be empty")

		expectedGatewayPrefix := fmt.Sprintf("projects/%s/locations/%s/agentGateways/", projectID, region)
		a.True(strings.HasPrefix(agentGatewayID, expectedGatewayPrefix), fmt.Sprintf("Agent Gateway ID should match expected prefix: %s", expectedGatewayPrefix))
		agentRegistryServiceIDs := terraform.OutputMap(t, mortgage.GetTFOptions(), "agent_registry_service_ids")

		expectedServices := []string{"legacy-dms", "corporate-email", "income-verification"}
		expectedServicePrefix := fmt.Sprintf("projects/%s/locations/%s/services/", projectID, region)

		for _, svcKey := range expectedServices {
			svcID, exists := agentRegistryServiceIDs[svcKey]

			a.True(exists, fmt.Sprintf("Agent Registry Service ID for '%s' was expected but not found in outputs", svcKey))

			if exists {
				a.NotEmpty(svcID, fmt.Sprintf("Agent Registry Service ID for '%s' should not be empty", svcKey))
				a.True(strings.HasPrefix(svcID, expectedServicePrefix), fmt.Sprintf("Service ID for '%s' should match expected prefix: %s", svcKey, expectedServicePrefix))
			}
		}
	})

	mortgage.DefineTeardown(func(a *assert.Assertions) {
		mortgage.DefaultTeardown(a)
	})

	mortgage.Test()
}
