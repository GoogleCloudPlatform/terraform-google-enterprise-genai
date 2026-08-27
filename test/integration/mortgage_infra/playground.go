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
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type playgroundTurns struct {
	Turn1 string `json:"turn1"`
	Turn2 string `json:"turn2"`
}

func exampleDir() string {
	_, thisFile, _, _ := runtime.Caller(0)
	return filepath.Clean(filepath.Join(filepath.Dir(thisFile), "../../../examples/mortgage-agent"))
}

func testDir() string {
	_, thisFile, _, _ := runtime.Caller(0)
	return filepath.Dir(thisFile)
}

func runBashFile(t *testing.T, path string, env []string) {
	t.Helper()
	raw, err := os.ReadFile(path)
	require.NoError(t, err)
	script := strings.ReplaceAll(string(raw), "\r\n", "\n")
	cmd := exec.Command("bash", "-c", script)
	cmd.Env = append(os.Environ(), env...)
	cmd.Dir = exampleDir()
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	require.NoError(t, cmd.Run(), "script %s failed", path)
}

func deleteReasoningEngine(t *testing.T, projectID, region, engineName string) {
	t.Helper()
	id := engineName
	if i := strings.LastIndex(engineName, "/"); i >= 0 {
		id = engineName[i+1:]
	}
	url := "https://" + region + "-aiplatform.googleapis.com/v1beta1/projects/" + projectID + "/locations/" + region + "/reasoningEngines/" + id + "?force=true"
	cmd := exec.Command("bash", "-c", "curl -fsS -X DELETE -H \"Authorization: Bearer $(gcloud auth print-access-token)\" "+url)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		t.Logf("reasoning engine delete failed (continuing): %v", err)
	}
}

func reasoningEngineFile() string {
	return filepath.Join(exampleDir(), ".cft-reasoning-engine")
}

func applyAgentRuntime(t *testing.T, projectID, projectNumber, orgID, region, registryURL, gatewayID, invokerEmail, stagingBucket, mcpDNSDomain string) {
	t.Helper()

	outFile := reasoningEngineFile()
	runBashFile(t, filepath.Join(testDir(), "deploy_runtime.sh"), []string{
		"PROJECT_ID=" + projectID,
		"PROJECT_NUMBER=" + projectNumber,
		"ORG_ID=" + orgID,
		"REGION=" + region,
		"EXAMPLE_DIR=" + exampleDir(),
		"ARTIFACT_REGISTRY_URL=" + registryURL,
		"AGENT_GATEWAY_ID=" + gatewayID,
		"MCP_INVOKER_SA=" + invokerEmail,
		"STAGING_BUCKET=" + stagingBucket,
		"MCP_INTERNAL_DNS_DOMAIN=" + strings.TrimSuffix(mcpDNSDomain, "."),
		"AGENT_ENGINE_OUT=" + outFile,
		"HOME=" + os.Getenv("HOME"),
		"PATH=" + os.Getenv("PATH") + ":" + filepath.Join(os.Getenv("HOME"), ".local/bin"),
	})

	engineBytes, err := os.ReadFile(outFile)
	require.NoError(t, err)
	engine := strings.TrimSpace(string(engineBytes))
	require.NotEmpty(t, engine)
}

func verifyAgentChat(t *testing.T, assert *assert.Assertions, projectID, region string) {
	t.Helper()

	engineBytes, err := os.ReadFile(reasoningEngineFile())
	require.NoError(t, err)
	engine := strings.TrimSpace(string(engineBytes))
	require.NotEmpty(t, engine)
	t.Cleanup(func() { deleteReasoningEngine(t, projectID, region, engine) })

	chatPath := filepath.Join(testDir(), "playground_chat.py")
	rawChat, err := os.ReadFile(chatPath)
	require.NoError(t, err)
	chatScript := strings.ReplaceAll(string(rawChat), "\r\n", "\n")
	tmpChat := filepath.Join(t.TempDir(), "playground_chat.py")
	require.NoError(t, os.WriteFile(tmpChat, []byte(chatScript), 0o644))

	uv := "uv"
	if _, err := exec.LookPath(uv); err != nil {
		uv = filepath.Join(os.Getenv("HOME"), ".local/bin", "uv")
	}
	cmd := exec.Command(uv, "run", "python", tmpChat,
		"--project", projectID,
		"--region", region,
		"--engine", engine)
	cmd.Dir = filepath.Join(exampleDir(), "src/mortgage_agent")
	cmd.Env = append(os.Environ(),
		"PATH="+os.Getenv("PATH")+":"+filepath.Join(os.Getenv("HOME"), ".local/bin"),
	)
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	t.Logf("playground_chat.py stdout:\n%s", out)
	require.NoError(t, err, "playground_chat.py failed")

	var turns playgroundTurns
	require.NoError(t, json.Unmarshal(out, &turns), "chat JSON: %s", out)

	assertPlaygroundTurns(t, assert, turns)
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

func orgID() string {
	if v := os.Getenv("TF_VAR_org_id"); v != "" {
		return v
	}
	return os.Getenv("ORG_ID")
}

func projectNumber() string {
	if v := os.Getenv("TF_VAR_project_number"); v != "" {
		return v
	}
	return os.Getenv("PROJECT_NUMBER")
}
