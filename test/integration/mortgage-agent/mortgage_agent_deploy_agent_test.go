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

package mortgage_agent

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

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

func deleteReasoningEngine(t *testing.T, projectID, region, engineResourceName, impersonateSA string) {
	t.Helper()
	if engineResourceName == "" {
		return
	}

	resourcePath := engineResourceName
	if !strings.HasPrefix(engineResourceName, "projects/") {
		resourcePath = fmt.Sprintf("projects/%s/locations/%s/reasoningEngines/%s", projectID, region, engineResourceName)
	}

	impersonateFlag := ""
	if impersonateSA != "" {
		impersonateFlag = fmt.Sprintf(" --impersonate-service-account=%s", impersonateSA)
	}
	url := fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1/%s?force=true", region, resourcePath)
	cmdStr := fmt.Sprintf(
		`curl -sS -X DELETE -H "Authorization: Bearer $(gcloud auth print-access-token%s)" "%s"`,
		impersonateFlag,
		url,
	)

	t.Logf("Deleting Reasoning Engine: %s", resourcePath)
	cmd := exec.Command("bash", "-c", cmdStr)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Logf("Reasoning Engine delete failed (continuing teardown): %v\nOutput:\n%s", err, string(out))
		return
	}
	t.Logf("Reasoning Engine deleted: %s", resourcePath)
}

func TestMortgageDeployAgent(t *testing.T) {
	vars := map[string]interface{}{
		"mcp_internal_dns_zone": map[string]interface{}{
			"name":   "mcp-server-internal",
			"domain": "mcp.mortgage.internal.",
		},
	}

	mortgageAgent := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
		tft.WithVars(vars),
	)

	mortgageAgent.DefineVerify(func(assert *assert.Assertions) {
		projectID := mortgageAgent.GetStringOutput("project_id")
		region := mortgageAgent.GetStringOutput("region")
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

			// Extract numeric agent ID from reasoning engine resource name
			agentIDParts := strings.Split(reasoningEngineName, "/")
			agentID := agentIDParts[len(agentIDParts)-1]
			egressScriptPath := filepath.Join(exampleDir, "scripts", "grant_agent_mcp_egress.sh")

			// Grant the agent per-MCP-server egress permissions
			t.Logf("Granting unconditional IAP Egressor role to agent %s on legacy-dms and income-verification MCP servers...", agentID)
			runExecCmd(t, exampleDir, pythonEnv, "bash", egressScriptPath,
				"--mcp",
				"--agent-id", agentID,
				"--mcp-filter", "legacy-dms income-verification",
			)

			t.Logf("Granting conditional IAP Egressor role (ReadOnlyToolsOnly CEL) to agent %s on corporate-email MCP server...", agentID)
			runExecCmd(t, exampleDir, pythonEnv, "bash", egressScriptPath,
				"--mcp",
				"--agent-id", agentID,
				"--mcp-filter", "corporate-email",
				"--condition-expression", "api.getAttribute('iap.googleapis.com/mcp.tool.isReadOnly', false) == true || api.getAttribute('iap.googleapis.com/mcp.toolName','')==''",
				"--condition-title", "ReadOnlyToolsOnly",
				"--condition-description", fmt.Sprintf("Restrict %s to read-only tools on corporate-email", agentID),
			)

			t.Logf("Granting IAP Egressor role to agent %s on registered endpoints...", agentID)
			runExecCmd(t, exampleDir, pythonEnv, "bash", egressScriptPath,
				"--agent-id", agentID,
				"--endpoints",
			)
		})
	})

	mortgageAgent.DefineTeardown(func(a *assert.Assertions) {
		exampleDir, err := filepath.Abs("../../../examples/mortgage-agent")
		a.NoError(err, "Failed to resolve blueprint root directory")

		projectID := mortgageAgent.GetStringOutput("project_id")
		region := mortgageAgent.GetStringOutput("region")
		terraformSA := mortgageAgent.GetStringOutput("terraform_service_account")
		if engineName := resolveReasoningEngineForTeardown(exampleDir); engineName != "" {
			deleteReasoningEngine(t, projectID, region, engineName, terraformSA)
		} else {
			t.Log("No Reasoning Engine resource name found for teardown; skipping delete")
		}

		mortgageAgent.DefaultTeardown(a)
	})

	mortgageAgent.Test()
}
