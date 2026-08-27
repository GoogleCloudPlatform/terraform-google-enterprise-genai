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
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
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
		"enable_model_armor":                     false,
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

	mortgage.Test()

	// mortgage.DefineVerify(func(assert *assert.Assertions) {
	// 	mortgage.DefaultVerify(a)

	// 	terraformSA := mortgage.GetStringOutput("terraform_service_account")
	// 	parentFolder := testutils.GetLastSplitElement(mortgage.GetStringOutput("parent_resource_id"), "/")

	//Networking

	//network_self_link
	//subnet_self_link
	//psc_subnet_self_link
	//psc_subnet_id

	//KMS

	//PSC Interface

	//Zones

	//Certificate
	//regional_certificate_name
	//mcp_ssl_certificate_id

	// MCPS
	// cloudbuild_bucket
	// Internal Load Balancer

	// Cloud Run
	// agent_mcp_invoker_email
	// mcp_service_account_emails
	// mcp_service_urls
	// mcp_service_names

	//Agent Gateway

	//Observability

	//Agent Registry

	// })

	// 		phase := strings.ToLower(strings.TrimSpace(os.Getenv("VERIFY_PHASE")))
	// 		projectID := mortgage.GetStringOutput("project_id")
	// 		region := mortgage.GetStringOutput("region")
	// 		staging := fmt.Sprintf("gs://%s-mcp-cloudbuild", projectID)

	// 		runInfra := phase == "" || phase == "all" || phase == "infra"
	// 		runApplyAgent := phase == "" || phase == "all" || phase == "apply-agent"
	// 		runVerifyAgent := phase == "" || phase == "all" || phase == "verify-agent"
	// 		if phase != "" && phase != "all" && phase != "infra" && phase != "apply-agent" && phase != "verify-agent" {
	// 			t.Fatalf("unknown VERIFY_PHASE=%q (use infra, apply-agent, verify-agent, or all)", phase)
	// 		}

	// 		if runInfra {
	// 			verifyInfra(t, assert, mortgage, mcpDomain, providedCertID)
	// 		}
	// 		if runApplyAgent {
	// 			applyAgentRuntime(
	// 				t,
	// 				projectID,
	// 				projectNumber,
	// 				orgID(),
	// 				region,
	// 				mortgage.GetStringOutput("artifact_registry_url"),
	// 				mortgage.GetStringOutput("agent_gateway_id"),
	// 				mortgage.GetStringOutput("agent_mcp_invoker_email"),
	// 				staging,
	// 				mortgage.GetStringOutput("mcp_internal_dns_domain"),
	// 			)
	// 		}
	// 		if runVerifyAgent {
	// 			verifyAgentChat(t, assert, projectID, region)
	// 		}
	// 	})

	// 	mortgage.Test()
	// }

	// func verifyInfra(t *testing.T, assert *assert.Assertions, mortgage *tft.TFBlueprintTest, mcpDomain, providedCertID string) {
	// 	t.Helper()

	// 	projectID := mortgage.GetStringOutput("project_id")
	// 	region := mortgage.GetStringOutput("region")
	// 	assert.NotEmpty(projectID)
	// 	assert.NotEmpty(region)
	// 	assert.NotEmpty(mortgage.GetStringOutput("vpc_id"))
	// 	assert.NotEmpty(mortgage.GetStringOutput("agent_gateway_id"))
	// 	assert.NotEmpty(mortgage.GetStringOutput("mcp_internal_lb_ip"))
	// 	assert.NotEmpty(mortgage.GetStringOutput("agent_mcp_invoker_email"))
	// 	assert.Equal(strings.TrimSuffix(mcpDomain, ".")+".", mortgage.GetStringOutput("mcp_internal_dns_domain"))

	// 	attachedCertID := mortgage.GetStringOutput("mcp_ssl_certificate_id")
	// 	assert.NotEmpty(attachedCertID)
	// 	if providedCertID != "" {
	// 		assert.Equal(providedCertID, attachedCertID)
	// 	}

	// 	op := gcloud.Runf(t, "compute networks describe %s --project %s", mortgage.GetStringOutput("vpc_name"), projectID)
	// 	assert.Equal("REGIONAL", op.Get("routingConfig.routingMode").String())
	// 	assert.Contains(mortgage.GetStringOutput("agent_gateway_id"), "agent-gateway")

	// certProject := projectID
	// certLocation := region
	// certName := attachedCertID
	//
	//	if strings.HasPrefix(attachedCertID, "projects/") {
	//		parts := strings.Split(attachedCertID, "/")
	//		if len(parts) >= 6 {
	//			certProject = parts[1]
	//			certLocation = parts[3]
	//			certName = parts[5]
	//		}
	//	} else if i := strings.LastIndex(attachedCertID, "/"); i >= 0 {
	//
	//		certName = attachedCertID[i+1:]
	//	}
	//
	// state := strings.TrimSpace(gcloud.RunCmd(t, fmt.Sprintf(
	//
	//	"certificate-manager certificates describe %s --location=%s --project=%s",
	//	certName, certLocation, certProject,
	//
	// ), gcloud.WithCommonArgs([]string{"--format", "value(managed.state)"})))
	// assert.Equal("ACTIVE", state)
}
