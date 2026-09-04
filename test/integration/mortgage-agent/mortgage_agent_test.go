// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//	https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package integration

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/stretchr/testify/assert"
)

func runExecCmd(t *testing.T, dir string, env []string, name string, args ...string) string {
	t.Helper()
	cmd := exec.Command(name, args...)
	if dir != "" {
		cmd.Dir = dir
	}
	if len(env) > 0 {
		cmd.Env = append(os.Environ(), env...)
	}
	out, err := cmd.CombinedOutput()
	outputStr := string(out)
	if err != nil {
		t.Fatalf("Command '%s %s' failed: %v\nOutput:\n%s", name, strings.Join(args, " "), err, outputStr)
	}
	return outputStr
}

type playgroundTurns struct {
	Turn1 string `json:"turn1"`
	Turn2 string `json:"turn2"`
}

const (
	turn1Prompt = "I am reviewing the Sterling familys current application. Can you summarize their 2024 and 2025 tax returns and verify if their total household income meets our 2026 debt-to-income requirements?"
	turn2Prompt = "Can you send a summary of this to my email jane@example.com"
)

func curlReasoningEngineQuery(t *testing.T, region, engineResourceName, userMessage string) (string, error) {
	t.Helper()

	endpoint := fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1beta1/%s:query", region, engineResourceName)

	reqBodyMap := map[string]interface{}{
		"class_method": "query",
		"input": map[string]interface{}{
			"message": userMessage,
			"user_id": "cft-playground",
		},
	}

	reqBodyBytes, err := json.Marshal(reqBodyMap)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request payload: %w", err)
	}

	cmdStr := fmt.Sprintf(
		`curl -sS -X POST "%s" `+
			`-H "Authorization: Bearer $(gcloud auth print-access-token)" `+
			`-H "Content-Type: application/json" `+
			`-d '%s'`,
		endpoint,
		string(reqBodyBytes),
	)

	var outputStr string
	maxAttempts := 5
	for i := 1; i <= maxAttempts; i++ {
		cmd := exec.Command("bash", "-c", cmdStr)
		out, runErr := cmd.CombinedOutput()
		outputStr = string(out)

		if runErr == nil && !strings.Contains(outputStr, `"error"`) && len(outputStr) > 0 {
			return outputStr, nil
		}

		t.Logf("Attempt %d/%d failed: %v | Response: %s", i, maxAttempts, runErr, outputStr)
		time.Sleep(time.Duration(15*i) * time.Second)
	}

	return outputStr, fmt.Errorf("reasoning engine query failed after %d attempts: %s", maxAttempts, outputStr)
}

const reasoningEngineOutFile = ".cft-reasoning-engine"

func reasoningEngineOutPath(exampleDir string) string {
	return filepath.Join(exampleDir, reasoningEngineOutFile)
}

func resolveReasoningEngineForTeardown(exampleDir string) string {
	if outPath := os.Getenv("AGENT_ENGINE_OUT"); outPath != "" {
		if data, err := os.ReadFile(outPath); err == nil {
			if name := strings.TrimSpace(string(data)); name != "" {
				return name
			}
		}
	}
	if data, err := os.ReadFile(reasoningEngineOutPath(exampleDir)); err == nil {
		return strings.TrimSpace(string(data))
	}
	return ""
}

func deleteReasoningEngine(t *testing.T, region, engineResourceName, impersonateSA string) {
	t.Helper()
	if engineResourceName == "" {
		return
	}

	impersonateFlag := ""
	if impersonateSA != "" {
		impersonateFlag = fmt.Sprintf(" --impersonate-service-account=%s", impersonateSA)
	}
	url := fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1beta1/%s?force=true", region, engineResourceName)
	cmdStr := fmt.Sprintf(
		`curl -sS -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token%s)" "%s"`,
		impersonateFlag,
		url,
	)

	t.Logf("Deleting Reasoning Engine: %s", engineResourceName)
	cmd := exec.Command("bash", "-c", cmdStr)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Logf("Reasoning Engine delete failed (continuing teardown): %v\nOutput:\n%s", err, string(out))
		return
	}
	t.Logf("Reasoning Engine deleted: %s", engineResourceName)
}

func assertPlaygroundTurns(t *testing.T, assert *assert.Assertions, turns playgroundTurns) {
	t.Helper()
	t.Logf("Playground turn 1:\n%s", turns.Turn1)
	t.Logf("Playground turn 2:\n%s", turns.Turn2)

	turn1 := strings.ToLower(turns.Turn1)
	turn2 := strings.ToLower(turns.Turn2)
	assert.NotEmpty(turns.Turn1)
	assert.NotEmpty(turns.Turn2)

	assert.NotContains(turn1, `"count": 0`, "list_mcp_connections must not return an empty registry")
	assert.NotContains(turn1, `"count":0`, "list_mcp_connections must not return an empty registry")
	assert.False(
		strings.Contains(turn1, "no mcp services") ||
			strings.Contains(turn1, "were discovered") ||
			strings.Contains(turn1, "unable to perform"),
		"turn 1 must not refuse for missing MCP discovery: %s", turns.Turn1,
	)
	assert.Contains(turn1, "sterling", "turn 1 should use Document Management / income tools for the Sterling family")
	assert.True(
		strings.Contains(turn1, "search_documents") ||
			strings.Contains(turn1, "get_document") ||
			strings.Contains(turn1, "verify_applicant") ||
			strings.Contains(turn1, "legacy_dms") ||
			strings.Contains(turn1, "income_verification"),
		"turn 1 should call DMS or income MCP tools: %s", turns.Turn1,
	)
	assert.True(
		strings.Contains(turn1, "tax") ||
			strings.Contains(turn1, "income") ||
			strings.Contains(turn1, "dti") ||
			strings.Contains(turn1, "agi"),
		"turn 1 should summarize tax returns or income/DTI: %s", turns.Turn1,
	)

	for _, ssn := range []string{"323-45-6789", "321-54-9876", "323456789", "321549876"} {
		assert.NotContains(turns.Turn1, ssn, "SSNs must be redacted in the Playground response")
		assert.NotContains(turns.Turn2, ssn, "SSNs must be redacted in the Playground response")
	}

	assert.False(
		strings.Contains(turn2, "cannot send") ||
			strings.Contains(turn2, "not authorized") ||
			strings.Contains(turn2, "permission denied") ||
			strings.Contains(turn2, "403") ||
			strings.Contains(turn2, "do not have access") ||
			strings.Contains(turn2, "unable to") ||
			strings.Contains(turn2, "no mcp"),
		"IAP is DRY_RUN so the email tool should succeed: %s", turns.Turn2,
	)
	assert.True(
		strings.Contains(turn2, "send_email") ||
			strings.Contains(turn2, "sent") ||
			strings.Contains(turn2, "message_id") ||
			strings.Contains(turn2, "successfully"),
		"turn 2 should confirm the summary email was sent: %s", turns.Turn2,
	)
}

func TestMortgageAgent(t *testing.T) {
	temp := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
	)
	random := temp.GetTFSetupStringOutput("random")
	dnsZoneDomain := temp.GetTFSetupStringOutput("dns_zone_domain")

	vars := map[string]interface{}{
		"kms_prevent_destroy":  false,
		"bucket_force_destroy": true,
		"mcp_internal_dns_zone": map[string]interface{}{
			"name":   "mcp-server-internal",
			"domain": "mcp." + dnsZoneDomain,
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

	mortgageAgent := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
		tft.WithVars(vars),
	)

	mortgageAgent.DefineVerify(func(assert *assert.Assertions) {
		mortgageAgent.DefaultVerify(assert)

		projectID := mortgageAgent.GetStringOutput("project_id")
		region := mortgageAgent.GetStringOutput("region")
		artifactRegistryURL := mortgageAgent.GetStringOutput("artifact_registry_url")
		agentGatewayID := mortgageAgent.GetStringOutput("agent_gateway_id")
		mcpInvokerSA := mortgageAgent.GetStringOutput("agent_mcp_invoker_email")
		stagingBucket := mortgageAgent.GetStringOutput("cloudbuild_bucket")
		mcpInternalDNSDomain := mortgageAgent.GetStringOutput("mcp_internal_dns_domain")
		terraformSA := mortgageAgent.GetStringOutput("terraform_service_account")
		orgID := mortgageAgent.GetStringOutput("org_id")
		projectNumber := mortgageAgent.GetStringOutput("project_number")

		exampleDir, err := filepath.Abs("../../../examples/mortgage-agent")
		assert.NoError(err, "Failed to resolve blueprint root directory")

		gcsStaging := strings.TrimPrefix(stagingBucket, "gs://")

		t.Run("DeployCloudRunServices", func(t *testing.T) {
			services := []struct {
				name     string
				tmplName string
				src      string
			}{
				{
					name:     "legacy-dms",
					tmplName: "legacy-dms",
					src:      filepath.Join(exampleDir, "src/legacy-dms"),
				},
				{
					name:     "corporate-email",
					tmplName: "corporate-email",
					src:      filepath.Join(exampleDir, "src/corporate-email"),
				},
				{
					name:     "income-verification",
					tmplName: "income-verification-api",
					src:      filepath.Join(exampleDir, "src/income-verification-api"),
				},
			}

			envMap := map[string]string{
				"PROJECT_ID":  projectID,
				"REGION":      region,
				"MCP_INGRESS": mortgageAgent.GetStringOutput("mcp_cloud_run_ingress_annotation"),
				"BUCKET_NAME": gcsStaging,
				"DOMAIN_NAME": strings.TrimSuffix(mcpInternalDNSDomain, "."),
			}
			mapper := func(placeholderName string) string {
				return envMap[placeholderName]
			}

			for _, svc := range services {
				image := fmt.Sprintf("%s/%s:cft", artifactRegistryURL, svc.name)
				cbYaml := fmt.Sprintf(`steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '%s', '.']
images:
  - '%s'
serviceAccount: 'projects/%s/serviceAccounts/%s'
`, image, image, projectID, terraformSA)

				cbPath := filepath.Join(svc.src, "cloudbuild.yaml")
				err = os.WriteFile(cbPath, []byte(cbYaml), 0644)
				assert.NoError(err, "Failed to write temporary cloudbuild.yaml for "+svc.name)

				t.Logf("Building %s...", svc.name)
				buildArgs := []string{
					"builds", "submit", svc.src,
					"--config=" + cbPath,
					"--project=" + projectID,
					"--gcs-source-staging-dir=gs://" + gcsStaging + "/mcp-src/" + svc.name,
					"--gcs-log-dir=gs://" + gcsStaging + "/mcp-logs/" + svc.name,
					"--impersonate-service-account=" + terraformSA,
					"--quiet",
				}
				runExecCmd(t, "", nil, "gcloud", buildArgs...)
				os.Remove(cbPath)

				tmplPath := filepath.Join(exampleDir, "cloud_run", svc.tmplName+".yaml.tmpl")
				yamlBytes, err := os.ReadFile(tmplPath)
				assert.NoError(err, "Failed to read template: "+tmplPath)
				renderedYaml := os.Expand(string(yamlBytes), mapper)
				reImage := regexp.MustCompile(`(?m)^(\s*-\s*image:\s*).*$`)
				renderedYaml = reImage.ReplaceAllString(renderedYaml, "${1}"+image)
				yamlOutPath := filepath.Join(exampleDir, "cloud_run", svc.tmplName+".yaml")
				err = os.WriteFile(yamlOutPath, []byte(renderedYaml), 0644)
				assert.NoError(err, "Failed to write rendered yaml: "+yamlOutPath)
				t.Logf("Deploying %s with YAML template...", svc.name)
				replaceArgs := []string{
					"run", "services", "replace", yamlOutPath,
					"--project=" + projectID,
					"--region=" + region,
					"--impersonate-service-account=" + terraformSA,
					"--quiet",
				}
				runExecCmd(t, "", nil, "gcloud", replaceArgs...)
				crJSON := gcloud.Runf(t, "run services describe %s --project=%s --region=%s --impersonate-service-account=%s --format=json",
					svc.name, projectID, region, terraformSA,
				)

				readyCondition := crJSON.Get("status.conditions.#(type==\"Ready\").status").String()
				assert.Equal("True", readyCondition, fmt.Sprintf("Cloud Run service %s is not in Ready state", svc.name))
			}
		})

		t.Run("DeployReasoningEngineAgent", func(t *testing.T) {
			homeDir, err := os.UserHomeDir()
			assert.NoError(err, "Failed to get user home directory")

			runExecCmd(t, "", nil, "sh", "-c", "command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh")

			uvBin := "uv"
			uvLocalPath := filepath.Join(homeDir, ".local/bin/uv")
			if _, err := os.Stat(uvLocalPath); err == nil {
				uvBin = uvLocalPath
			}

			pythonEnv := []string{
				fmt.Sprintf("PATH=%s/.local/bin:%s", homeDir, os.Getenv("PATH")),
				fmt.Sprintf("PROJECT_ID=%s", projectID),
				fmt.Sprintf("PROJECT_NUMBER=%s", projectNumber),
				fmt.Sprintf("ORG_ID=%s", orgID),
				fmt.Sprintf("REGION=%s", region),
				fmt.Sprintf("MCP_INVOKER_SA_EMAIL=%s", mcpInvokerSA),
				fmt.Sprintf("MCP_INTERNAL_DNS_DOMAIN=%s", mcpInternalDNSDomain),
				fmt.Sprintf("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=%s", terraformSA),
			}
			agentDir := filepath.Join(exampleDir, "src/mortgage_agent")

			runExecCmd(t, agentDir, pythonEnv, uvBin, "python", "install", "3.12")
			runExecCmd(t, agentDir, pythonEnv, uvBin, "sync", "--frozen")

			t.Log("Granting IAP Egressor role to all agents...")
			egressScriptPath := filepath.Join(exampleDir, "scripts", "grant_agent_mcp_egress.sh")
			runExecCmd(t, exampleDir, pythonEnv, "bash", egressScriptPath, "--bind-all-agents", "--endpoints")

			deployArgs := []string{
				"run", "python", "deploy_agent.py",
				fmt.Sprintf("--project=%s", projectID),
				fmt.Sprintf("--region=%s", region),
				fmt.Sprintf("--staging-bucket=gs://%s", gcsStaging),
				"--enable-agent-identity",
				"--agent-name=mortgage-agent",
				"--display-name=Mortgage Assistant",
				fmt.Sprintf("--agent-gateway=%s", agentGatewayID),
				fmt.Sprintf("--mcp-invoker-sa=%s", mcpInvokerSA),
				fmt.Sprintf("--mcp-dns-domain=%s", mcpInternalDNSDomain),
				"--model-endpoint-location=global",
			}

			t.Log("Running deploy_agent.py (Agent Engine create typically takes 15–45 minutes; monitor Cloud Build in the GCP console)...")
			deployLog := runExecCmd(t, agentDir, pythonEnv, uvBin, deployArgs...)

			re := regexp.MustCompile(`projects/[^[:space:]]+/locations/[^[:space:]]+/reasoningEngines/[0-9]+`)
			matches := re.FindAllString(deployLog, -1)
			assert.NotEmpty(matches, "Could not parse reasoning engine name from deploy output")

			reasoningEngineName := matches[len(matches)-1]
			t.Logf("Reasoning Engine deployed successfully: %s", reasoningEngineName)

			err = os.WriteFile(reasoningEngineOutPath(exampleDir), []byte(reasoningEngineName+"\n"), 0644)
			assert.NoError(err, "Failed to write reasoning engine resource name for teardown")

			if outPath := os.Getenv("AGENT_ENGINE_OUT"); outPath != "" {
				err = os.WriteFile(outPath, []byte(reasoningEngineName+"\n"), 0644)
				assert.NoError(err, "Failed to write AGENT_ENGINE_OUT file")
			}

			certSSLID := os.Getenv("TF_VAR_certificate_ssl_id")
			dnsZone := os.Getenv("TF_VAR_dns_zone_domain")
			if certSSLID == "" || dnsZone == "" {
				t.Log("Skipping agent chat test: TF_VAR_certificate_ssl_id or TF_VAR_dns_zone_domain is empty.")
				return
			}

			t.Log("Waiting 30s for the Reasoning Engine revision to stabilize...")
			time.Sleep(30 * time.Second)

			t.Log("Sending Turn 1 to Reasoning Engine via CURL...")
			turn1Resp, err := curlReasoningEngineQuery(t, region, reasoningEngineName, turn1Prompt)
			assert.NoError(err, "Turn 1 request failed")

			time.Sleep(10 * time.Second)

			t.Log("Sending Turn 2 (Email) to Reasoning Engine via CURL...")
			turn2Resp, err := curlReasoningEngineQuery(t, region, reasoningEngineName, turn2Prompt)
			assert.NoError(err, "Turn 2 request failed")

			turns := playgroundTurns{
				Turn1: turn1Resp,
				Turn2: turn2Resp,
			}

			assertPlaygroundTurns(t, assert, turns)
		})
	})

	mortgageAgent.DefineTeardown(func(a *assert.Assertions) {
		exampleDir, err := filepath.Abs("../../../examples/mortgage-agent")
		a.NoError(err, "Failed to resolve blueprint root directory")

		region := mortgageAgent.GetStringOutput("region")
		terraformSA := mortgageAgent.GetStringOutput("terraform_service_account")
		if engineName := resolveReasoningEngineForTeardown(exampleDir); engineName != "" {
			deleteReasoningEngine(t, region, engineName, terraformSA)
		} else {
			t.Log("No Reasoning Engine resource name found for teardown; skipping delete")
		}

		mortgageAgent.DefaultTeardown(a)
	})

	mortgageAgent.Test()
}
