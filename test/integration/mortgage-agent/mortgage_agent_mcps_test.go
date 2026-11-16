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
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestMortgageAgentMCPs(t *testing.T) {
	setupOutput := tft.NewTFBlueprintTest(t, tft.WithTFDir("../../setup"))
	serviceAccount := setupOutput.GetStringOutput("terraform_service_account")

	err := os.Setenv("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", serviceAccount)
	if err != nil {
		t.Fatalf("failed to set GOOGLE_IMPERSONATE_SERVICE_ACCOUNT: %v", err)
	}

	exampleDir, err := filepath.Abs("../../../examples/mortgage-agent")
	if err != nil {
		t.Fatalf("failed to get absolute path for example dir: %v", err)
	}

	standalone := tft.NewTFBlueprintTest(t,
		tft.WithTFDir(exampleDir),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	services := []struct {
		fileName    string
		serviceName string
		srcDir      string
	}{
		{"legacy-dms", "legacy-dms", "legacy-dms"},
		{"income-verification-api", "income-verification", "income-verification-api"},
		{"corporate-email", "corporate-email", "corporate-email"},
	}

	standalone.DefineVerify(func(a *assert.Assertions) {
		projectID := standalone.GetStringOutput("project_id")
		region := standalone.GetStringOutput("region")
		cloudbuildBucket := standalone.GetStringOutput("cloudbuild_bucket")
		mcpIngress := standalone.GetStringOutput("mcp_cloud_run_ingress_annotation")
		domainName := standalone.GetStringOutput("mcp_internal_dns_domain")

		tmpDir := t.TempDir()

		replacer := strings.NewReplacer(
			"${PROJECT_ID}", projectID,
			"${REGION}", region,
			"${MCP_INGRESS}", mcpIngress,
			"${DOMAIN_NAME}", domainName,
		)

		for _, svc := range services {
			// Build and Push Image
			srcPath := filepath.Join(exampleDir, "src", svc.srcDir)
			image := fmt.Sprintf("%s-docker.pkg.dev/%s/gateway-docker/%s:latest", region, projectID, svc.fileName)
			t.Logf("Building image %s from %s...", image, srcPath)

			buildCmd := fmt.Sprintf("builds submit %s --tag %s --gcs-source-staging-dir gs://%s/source --service-account=projects/%s/serviceAccounts/%s --gcs-log-dir=gs://%s/logs --project %s --impersonate-service-account %s", srcPath, image, cloudbuildBucket, projectID, serviceAccount, cloudbuildBucket, projectID, serviceAccount)
			gcloud.RunCmd(t, buildCmd)

			// Render YAML
			tmplPath := filepath.Join(exampleDir, "cloud_run", svc.fileName+".yaml.tmpl")
			content, err := os.ReadFile(tmplPath)
			if err != nil {
				t.Fatalf("failed to read template %s: %v", tmplPath, err)
			}

			rendered := replacer.Replace(string(content))
			if strings.Contains(rendered, "${") {
				t.Fatalf("unresolved placeholders in %s: %s", tmplPath, rendered)
			}

			outPath := filepath.Join(tmpDir, svc.fileName+".yaml")
			err = os.WriteFile(outPath, []byte(rendered), 0644)
			if err != nil {
				t.Fatalf("failed to write %s: %v", outPath, err)
			}

			// Deploy Cloud Run Service
			t.Logf("Deploying Cloud Run service %s...", svc.serviceName)
			deployCmd := fmt.Sprintf("run services replace %s --region %s --project %s --impersonate-service-account %s", outPath, region, projectID, serviceAccount)
			gcloud.RunCmd(t, deployCmd)
		}

		// Validation Phase
		t.Log("Validating deployed MCP servers...")

		gcloudJsonOpts := gcloud.WithCommonArgs([]string{
			"--project", projectID,
			"--impersonate-service-account", serviceAccount,
			"--format", "json",
		})

		agentRegistryServiceIDs := terraform.OutputMap(t, standalone.GetTFOptions(), "agent_registry_service_ids")

		for _, svc := range services {
			t.Logf("Checking if Cloud Run service %s is Ready...", svc.serviceName)
			svcOp := gcloud.Run(t, fmt.Sprintf("run services describe %s --region %s", svc.serviceName, region), gcloudJsonOpts)
			readyCond := svcOp.Get("status.conditions.#(type==\"Ready\").status").String()
			a.Equal("True", readyCond, fmt.Sprintf("Cloud Run service %s should be in Ready status", svc.serviceName))

			url := svcOp.Get("status.url").String()
			a.NotEmpty(url, "Cloud Run URL should not be empty")

			t.Logf("Checking Agent Registry entry for %s...", svc.serviceName)
			svcID, exists := agentRegistryServiceIDs[svc.serviceName]
			a.True(exists, fmt.Sprintf("Agent Registry Service ID for '%s' was expected but not found", svc.serviceName))
			if exists {
				a.NotEmpty(svcID, "Agent Registry Service ID should not be empty")
			}
		}
	})
	standalone.Test()
}
