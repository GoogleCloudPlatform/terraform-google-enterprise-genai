// Copyright 2024-2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package mortgage_agent

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/assert"
	"github.com/tidwall/gjson"
	"golang.org/x/oauth2/google"
)

const (
	sleepBetweenRetries time.Duration = 10 * time.Second
	maxRetries          int           = 30
	userID                            = "e2e_user"
)

// tokenAuthTransport intercepts HTTP requests to add a Bearer authorization token.
// It prioritizes gcloud auth token with optional service account impersonation,
// falling back to Application Default Credentials (ADC).
type tokenAuthTransport struct {
	base          http.RoundTripper
	impersonateSA string
}

func (t *tokenAuthTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	reqCopy := req.Clone(req.Context())
	if reqCopy.Header.Get("Authorization") == "" {
		token, err := getAccessToken(reqCopy.Context(), t.impersonateSA)
		if err != nil {
			return nil, fmt.Errorf("failed to get access token: %w", err)
		}
		reqCopy.Header.Set("Authorization", "Bearer "+token)
	}
	return t.base.RoundTrip(reqCopy)
}

func getAccessToken(ctx context.Context, impersonateSA string) (string, error) {
	if impersonateSA == "" {
		impersonateSA = os.Getenv("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT")
	}
	if impersonateSA != "" {
		cmd := exec.CommandContext(ctx, "gcloud", "auth", "print-access-token", fmt.Sprintf("--impersonate-service-account=%s", impersonateSA))
		if out, err := cmd.Output(); err == nil {
			tok := strings.TrimSpace(string(out))
			if tok != "" {
				return tok, nil
			}
		}
	}
	cmd := exec.CommandContext(ctx, "gcloud", "auth", "print-access-token")
	if out, err := cmd.Output(); err == nil {
		tok := strings.TrimSpace(string(out))
		if tok != "" {
			return tok, nil
		}
	}
	ts, err := google.DefaultTokenSource(ctx, "https://www.googleapis.com/auth/cloud-platform")
	if err != nil {
		return "", err
	}
	tok, err := ts.Token()
	if err != nil {
		return "", err
	}
	return tok.AccessToken, nil
}

// agentEngineClient encapsulates REST calls to Agent Engine (reasoningEngines).
type agentEngineClient struct {
	httpClient   *http.Client
	baseURL      string // https://{location}-aiplatform.googleapis.com/v1/{resourceName}
	resourceName string // projects/{p}/locations/{l}/reasoningEngines/{id}
}

func newAgentEngineClient(ctx context.Context, resourceName, impersonateSA string) (*agentEngineClient, error) {
	// resourceName: projects/{project}/locations/{location}/reasoningEngines/{id}
	parts := strings.Split(resourceName, "/")
	if len(parts) != 6 || parts[0] != "projects" || parts[2] != "locations" || parts[4] != "reasoningEngines" {
		return nil, fmt.Errorf("invalid resource name: %q", resourceName)
	}
	location := parts[3]

	baseTransport := http.DefaultTransport
	httpClient := &http.Client{
		Timeout: 120 * time.Second,
		Transport: &tokenAuthTransport{
			base:          baseTransport,
			impersonateSA: impersonateSA,
		},
	}

	return &agentEngineClient{
		httpClient:   httpClient,
		baseURL:      fmt.Sprintf("https://%s-aiplatform.googleapis.com/v1/%s", location, resourceName),
		resourceName: resourceName,
	}, nil
}

func (c *agentEngineClient) do(ctx context.Context, method, url string, payload interface{}) ([]byte, error) {
	var body io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return nil, err
		}
		body = bytes.NewBuffer(data)
	}
	req, err := http.NewRequestWithContext(ctx, method, url, body)
	if err != nil {
		return nil, err
	}
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("status %d from %s: %s", resp.StatusCode, url, string(respBody))
	}
	return respBody, nil
}

// get verifies that the agent resource exists and is accessible.
func (c *agentEngineClient) get(ctx context.Context) (string, error) {
	body, err := c.do(ctx, http.MethodGet, c.baseURL, nil)
	if err != nil {
		return "", err
	}
	name := gjson.GetBytes(body, "name").String()
	if name == "" {
		return "", fmt.Errorf("response missing name field: %s", string(body))
	}
	return name, nil
}

// createSession calls the AdkApp create_session method via :query.
func (c *agentEngineClient) createSession(ctx context.Context, user string) (string, error) {
	payload := map[string]interface{}{
		"class_method": "create_session",
		"input":        map[string]interface{}{"user_id": user},
	}
	body, err := c.do(ctx, http.MethodPost, c.baseURL+":query", payload)
	if err != nil {
		return "", err
	}
	id := gjson.GetBytes(body, "output.id").String()
	if id == "" {
		id = gjson.GetBytes(body, "output.session_id").String()
	}
	if id == "" {
		id = gjson.GetBytes(body, "id").String()
	}
	if id == "" {
		return "", fmt.Errorf("session id not found in response: %s", string(body))
	}
	return id, nil
}

// extractTextFromJSON extracts text blocks from the format returned by ADK / Vertex AI models.
func extractTextFromJSON(jsonBytes []byte) []string {
	var texts []string
	val := gjson.ParseBytes(jsonBytes)

	extractNode := func(node gjson.Result) {
		node.Get("content.parts").ForEach(func(_, part gjson.Result) bool {
			if t := strings.TrimSpace(part.Get("text").String()); t != "" {
				texts = append(texts, t)
			}
			return true
		})
		node.Get("output.content.parts").ForEach(func(_, part gjson.Result) bool {
			if t := strings.TrimSpace(part.Get("text").String()); t != "" {
				texts = append(texts, t)
			}
			return true
		})
		node.Get("candidates").ForEach(func(_, cand gjson.Result) bool {
			cand.Get("content.parts").ForEach(func(_, part gjson.Result) bool {
				if t := strings.TrimSpace(part.Get("text").String()); t != "" {
					texts = append(texts, t)
				}
				return true
			})
			return true
		})
		if t := strings.TrimSpace(node.Get("text").String()); t != "" {
			texts = append(texts, t)
		}
		if t := strings.TrimSpace(node.Get("output.text").String()); t != "" {
			texts = append(texts, t)
		}
		if node.Get("output").Type == gjson.String {
			if t := strings.TrimSpace(node.Get("output").String()); t != "" {
				texts = append(texts, t)
			}
		}
	}

	if val.IsArray() {
		val.ForEach(func(_, item gjson.Result) bool {
			extractNode(item)
			return true
		})
	} else {
		extractNode(val)
	}
	return texts
}

// streamQuery calls the AdkApp stream_query method via :streamQuery and returns
// the concatenated text of all returned events. If :streamQuery fails,
// it attempts the query method via :query as a fallback.
func (c *agentEngineClient) streamQuery(ctx context.Context, user, sessionID, message string) (string, error) {
	streamPayload := map[string]interface{}{
		"class_method": "stream_query",
		"input": map[string]interface{}{
			"user_id":    user,
			"session_id": sessionID,
			"message":    message,
		},
	}
	body, err := c.do(ctx, http.MethodPost, c.baseURL+":streamQuery", streamPayload)
	if err == nil {
		var texts []string
		scanner := bufio.NewScanner(bytes.NewReader(body))
		scanner.Buffer(make([]byte, 0, 1024*1024), 10*1024*1024)
		for scanner.Scan() {
			line := strings.TrimSpace(strings.TrimPrefix(scanner.Text(), "data:"))
			if line == "" || !gjson.Valid(line) {
				continue
			}
			if errMsg := gjson.Get(line, "error_message").String(); errMsg != "" {
				return "", fmt.Errorf("agent returned error: %s", errMsg)
			}
			texts = append(texts, extractTextFromJSON([]byte(line))...)
		}
		if err := scanner.Err(); err == nil && len(texts) > 0 {
			return strings.Join(texts, "\n"), nil
		}
		if len(texts) == 0 && gjson.ValidBytes(body) {
			texts = extractTextFromJSON(body)
			if len(texts) > 0 {
				return strings.Join(texts, "\n"), nil
			}
		}
	}

	// Fallback to :query if :streamQuery did not return content
	queryPayload := map[string]interface{}{
		"class_method": "query",
		"input": map[string]interface{}{
			"user_id":    user,
			"session_id": sessionID,
			"message":    message,
		},
	}
	queryBody, queryErr := c.do(ctx, http.MethodPost, c.baseURL+":query", queryPayload)
	if queryErr == nil {
		texts := extractTextFromJSON(queryBody)
		if len(texts) > 0 {
			return strings.Join(texts, "\n"), nil
		}
	}

	if err != nil {
		return "", fmt.Errorf("streamQuery failed: %w", err)
	}
	if queryErr != nil {
		return "", fmt.Errorf("query fallback failed: %w", queryErr)
	}
	return "", fmt.Errorf("no text returned by the agent; raw response: %s", string(body))
}

// getReasoningEngineResource retrieves the resource name of the deployed Reasoning Engine.
// It checks environment variables, the file persisted during deploy (.cft-reasoning-engine),
// and falls back to gcloud query.
func getReasoningEngineResource(exampleDir, projectID, region, terraformSA string) string {
	if name := strings.TrimSpace(os.Getenv("AGENT_ENGINE_RESOURCE_NAME")); name != "" {
		return name
	}
	if name := resolveReasoningEngineForTeardown(exampleDir); name != "" {
		return name
	}
	if projectID != "" && region != "" {
		impersonateFlag := ""
		if terraformSA != "" {
			impersonateFlag = fmt.Sprintf(" --impersonate-service-account=%s", terraformSA)
		}
		cmdStr := fmt.Sprintf(
			"gcloud ai reasoning-engines list --project=%s --region=%s --format='value(name)'%s",
			projectID, region, impersonateFlag,
		)
		cmd := exec.Command("bash", "-c", cmdStr)
		if out, err := cmd.CombinedOutput(); err == nil {
			lines := strings.Split(strings.TrimSpace(string(out)), "\n")
			for i := len(lines) - 1; i >= 0; i-- {
				line := strings.TrimSpace(lines[i])
				if strings.Contains(line, "reasoningEngines/") {
					return line
				}
			}
		}
	}
	return ""
}

func TestMortgageAgentPlatformE2E(t *testing.T) {
	vars := map[string]interface{}{
		"mcp_internal_dns_zone": map[string]interface{}{
			"name":   "mcp-server-internal",
			"domain": "mcp.mortgage.internal.",
		},
	}

	agentPlatform := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/mortgage-agent"),
		tft.WithVars(vars),
	)

	agentPlatform.DefineVerify(func(assert *assert.Assertions) {
		projectID := agentPlatform.GetStringOutput("project_id")
		region := agentPlatform.GetStringOutput("region")
		terraformSA := agentPlatform.GetStringOutput("terraform_service_account")

		exampleDir, err := filepath.Abs("../../../examples/mortgage-agent")
		assert.NoError(err, "Failed to resolve blueprint root directory")

		// Get the resource name of the Reasoning Engine deployed in the TestMortgageDeployAgent step
		resourceName := getReasoningEngineResource(exampleDir, projectID, region, terraformSA)
		if !strings.HasPrefix(resourceName, "projects/") && resourceName != "" {
			resourceName = fmt.Sprintf("projects/%s/locations/%s/reasoningEngines/%s", projectID, region, resourceName)
		}
		assert.NotEmpty(resourceName, "No deployed reasoning engine found. Ensure TestMortgageDeployAgent has run successfully.")
		t.Logf("Reasoning Engine resource for E2E test: %s", resourceName)

		ctx := context.Background()
		client, err := newAgentEngineClient(ctx, resourceName, terraformSA)
		assert.NoError(err, "Failed to instantiate Agent Engine client")

		// Verify that the agent is deployed and accessible
		_, err = retry.DoWithRetryE(
			t,
			fmt.Sprintf("Verifying Agent Engine %s", resourceName),
			maxRetries,
			sleepBetweenRetries,
			func() (string, error) { return client.get(ctx) },
		)
		if err != nil {
			t.Fatalf("Agent Engine (%s) is not ready: %v", resourceName, err)
		}

		// Create ADK session
		sessionID, err := retry.DoWithRetryE(
			t,
			"Creating ADK session",
			maxRetries,
			sleepBetweenRetries,
			func() (string, error) { return client.createSession(ctx, userID) },
		)
		if err != nil {
			t.Fatalf("Failed to create session: %v", err)
		}
		t.Logf("ADK session created: %s", sessionID)

		// Prompt 1: underwriting inquiry
		prompt1 := "I am reviewing the Sterling familys current application. Can you summarize their 2024 and 2025 tax returns and verify if their total household income meets our 2026 debt-to-income requirements?"
		resp1, err := retry.DoWithRetryE(
			t,
			"Executing Prompt 1: Mortgage underwriting inquiry",
			maxRetries,
			sleepBetweenRetries,
			func() (string, error) { return client.streamQuery(ctx, userID, sessionID, prompt1) },
		)
		if err != nil {
			t.Fatalf("Prompt 1 failed: %v", err)
		}
		t.Logf("Prompt 1 response: %s", resp1)
		assert.NotEmpty(resp1)

		// Prompt 2: email dispatch inquiry (same session)
		prompt2 := "Can you send a summary of this to my email jane@example.com"
		resp2, err := retry.DoWithRetryE(
			t,
			"Executing Prompt 2: Email dispatch inquiry",
			maxRetries,
			sleepBetweenRetries,
			func() (string, error) { return client.streamQuery(ctx, userID, sessionID, prompt2) },
		)
		if err != nil {
			t.Fatalf("Prompt 2 failed: %v", err)
		}
		t.Logf("Prompt 2 response: %s", resp2)
		assert.NotEmpty(resp2)
	})

	agentPlatform.Test()
}
