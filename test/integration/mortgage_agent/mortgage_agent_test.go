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
	"os"
	"strings"
	"testing"
	"time"
	"unicode"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func uniqueTemplateSuffix() string {
	raw := strings.ToLower(os.Getenv("BUILD_ID"))
	var b strings.Builder
	for _, r := range raw {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
		}
	}
	s := b.String()
	if len(s) > 8 {
		s = s[:8]
	}
	if s == "" {
		s = fmt.Sprintf("t%d", time.Now().Unix()%100000000)
	}
	if s[0] >= '0' && s[0] <= '9' {
		s = "b" + s
		if len(s) > 8 {
			s = s[:8]
		}
	}
	return s
}

const mortgageExampleDir = "../../../examples/mortgage-agent"

func TestMortgageAgent(t *testing.T) {
	suffix := uniqueTemplateSuffix()
	dnsZoneDomain := os.Getenv("TF_VAR_dns_zone_domain")
	if dnsZoneDomain == "" {
		t.Fatal("TF_VAR_dns_zone_domain is required (public domain whose SANs are on the MCP cert, trailing dot)")
	}
	if !strings.HasSuffix(dnsZoneDomain, ".") {
		dnsZoneDomain += "."
	}
	mcpDomain := "mcp." + dnsZoneDomain

	providedCertID := strings.TrimSpace(os.Getenv("TF_VAR_mcp_ssl_certificate_id"))

	setup := tft.NewTFBlueprintTest(t, tft.WithTFDir(mortgageExampleDir))

	terraformSA := setup.GetTFSetupStringOutput("terraform_service_account")

	adminMembers := []string{fmt.Sprintf("serviceAccount:%s", terraformSA)}

	vars := map[string]interface{}{
		"kms_prevent_destroy":  false,
		"bucket_force_destroy": true,
		"dns_zone_domain":      dnsZoneDomain,
		"mcp_internal_dns_zone": map[string]interface{}{
			"name":   "mcp-server-internal",
			"domain": mcpDomain,
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
		"platform_admin_members":                 adminMembers,
		"mcp_lb_protocol":                        "HTTPS",
		"agent_gateway_iap_iam_enforcement_mode": "DRY_RUN",
		"enable_model_armor":                     true,
		"enable_model_armor_mcp_floor_setting":   false,
		"model_armor_pi_jailbreak_confidence":    "LOW_AND_ABOVE",
		"model_armor_request_template_id":        "agw-req-" + suffix,
		"model_armor_response_template_id":       "agw-resp-" + suffix,
		"model_armor_inspect_template_id":        "agw-insp-" + suffix,
		"model_armor_deidentify_template_id":     "agw-deid-" + suffix,
	}
	if providedCertID != "" {
		vars["mcp_ssl_certificate_id"] = providedCertID
	} else if os.Getenv("TF_VAR_dns_zone_name") == "" {
		t.Fatal("set TF_VAR_mcp_ssl_certificate_id (existing cert) or TF_VAR_dns_zone_name (delegated public Cloud DNS zone for DNS-01 issuance)")
	}
	if v := os.Getenv("TF_VAR_project_id"); v != "" {
		vars["project_id"] = v
	} else if pid := setup.GetTFSetupStringOutput("project_id"); pid != "" {
		vars["project_id"] = pid
	}
	projectNum := os.Getenv("TF_VAR_project_number")
	if projectNum == "" {
		projectNum = setup.GetTFSetupStringOutput("project_number")
	}
	if projectNum == "" {
		t.Fatal("project_number is required (TF_VAR_project_number or test/setup output)")
	}
	vars["project_number"] = projectNum
	_ = os.Setenv("TF_VAR_project_number", projectNum)
	if v := os.Getenv("TF_VAR_org_id"); v != "" {
		vars["org_id"] = v
	}
	if v := os.Getenv("TF_VAR_dns_zone_name"); v != "" && providedCertID == "" {
		vars["dns_zone_name"] = v
	}

	bpt := tft.NewTFBlueprintTest(t, tft.WithTFDir(mortgageExampleDir), tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		phase := strings.ToLower(strings.TrimSpace(os.Getenv("VERIFY_PHASE")))
		projectID := bpt.GetStringOutput("project_id")
		region := bpt.GetStringOutput("region")
		staging := fmt.Sprintf("gs://%s-mcp-cloudbuild", projectID)

		runApplyAgent := phase == "" || phase == "all" || phase == "apply-agent"
		runVerifyAgent := phase == "" || phase == "all" || phase == "verify-agent"
		if phase != "" && phase != "all" && phase != "infra" && phase != "apply-agent" && phase != "verify-agent" {
			t.Fatalf("unknown VERIFY_PHASE=%q (use infra, apply-agent, verify-agent, or all)", phase)
		}

		if runApplyAgent {
			applyAgentRuntime(
				t,
				projectID,
				projectNum,
				os.Getenv("TF_VAR_org_id"),
				region,
				bpt.GetStringOutput("artifact_registry_url"),
				bpt.GetStringOutput("agent_gateway_id"),
				bpt.GetStringOutput("agent_mcp_invoker_email"),
				staging,
				bpt.GetStringOutput("mcp_internal_dns_domain"),
			)
		}
		if runVerifyAgent {
			verifyAgentChat(t, assert, projectID, region)
		}
	})

	bpt.Test()
}
