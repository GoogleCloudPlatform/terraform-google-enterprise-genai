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

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

// uniqueTemplateSuffix is a short id for DLP/Model Armor template IDs.
// DLP rejects reuse of a deleted template_id, so CFT cannot keep a fixed name.
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

	vars := map[string]interface{}{
		"dns_zone_domain": dnsZoneDomain,
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
		"mcp_lb_protocol":                          "HTTPS",
		"agent_gateway_iap_iam_enforcement_mode":   "DRY_RUN",
		"enable_model_armor":                     true,
		"enable_model_armor_mcp_floor_setting":   false,
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
	}
	if v := os.Getenv("TF_VAR_project_number"); v != "" {
		vars["project_number"] = v
	}
	if v := os.Getenv("TF_VAR_org_id"); v != "" {
		vars["org_id"] = v
	}
	if v := os.Getenv("TF_VAR_dns_zone_name"); v != "" && providedCertID == "" {
		vars["dns_zone_name"] = v
	}

	bpt := tft.NewTFBlueprintTest(t, tft.WithVars(vars))

	bpt.DefineVerify(func(assert *assert.Assertions) {
		phase := strings.ToLower(strings.TrimSpace(os.Getenv("VERIFY_PHASE")))
		projectID := bpt.GetStringOutput("project_id")
		region := bpt.GetStringOutput("region")
		staging := fmt.Sprintf("gs://%s-mcp-cloudbuild", projectID)

		runInfra := phase == "" || phase == "all" || phase == "infra"
		runApplyAgent := phase == "" || phase == "all" || phase == "apply-agent"
		runVerifyAgent := phase == "" || phase == "all" || phase == "verify-agent"
		if phase != "" && phase != "all" && phase != "infra" && phase != "apply-agent" && phase != "verify-agent" {
			t.Fatalf("unknown VERIFY_PHASE=%q (use infra, apply-agent, verify-agent, or all)", phase)
		}

		if runInfra {
			verifyInfra(t, assert, bpt, mcpDomain, providedCertID)
		}
		if runApplyAgent {
			applyAgentRuntime(
				t,
				projectID,
				projectNumber(),
				orgID(),
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

func verifyInfra(t *testing.T, assert *assert.Assertions, bpt *tft.TFBlueprintTest, mcpDomain, providedCertID string) {
	t.Helper()

	projectID := bpt.GetStringOutput("project_id")
	region := bpt.GetStringOutput("region")
	assert.NotEmpty(projectID)
	assert.NotEmpty(region)
	assert.NotEmpty(bpt.GetStringOutput("vpc_id"))
	assert.NotEmpty(bpt.GetStringOutput("agent_gateway_id"))
	assert.NotEmpty(bpt.GetStringOutput("mcp_internal_lb_ip"))
	assert.NotEmpty(bpt.GetStringOutput("agent_mcp_invoker_email"))
	assert.Equal(strings.TrimSuffix(mcpDomain, ".")+".", bpt.GetStringOutput("mcp_internal_dns_domain"))

	attachedCertID := bpt.GetStringOutput("mcp_ssl_certificate_id")
	assert.NotEmpty(attachedCertID)
	if providedCertID != "" {
		assert.Equal(providedCertID, attachedCertID)
	}

	op := gcloud.Runf(t, "compute networks describe %s --project %s", bpt.GetStringOutput("vpc_name"), projectID)
	assert.Equal("REGIONAL", op.Get("routingConfig.routingMode").String())
	assert.Contains(bpt.GetStringOutput("agent_gateway_id"), "agent-gateway")

	certProject := projectID
	certLocation := region
	certName := attachedCertID
	if strings.HasPrefix(attachedCertID, "projects/") {
		parts := strings.Split(attachedCertID, "/")
		if len(parts) >= 6 {
			certProject = parts[1]
			certLocation = parts[3]
			certName = parts[5]
		}
	} else if i := strings.LastIndex(attachedCertID, "/"); i >= 0 {
		certName = attachedCertID[i+1:]
	}
	state := strings.TrimSpace(gcloud.RunCmd(t, fmt.Sprintf(
		"certificate-manager certificates describe %s --location=%s --project=%s",
		certName, certLocation, certProject,
	), gcloud.WithCommonArgs([]string{"--format", "value(managed.state)"})))
	assert.Equal("ACTIVE", state)
}
