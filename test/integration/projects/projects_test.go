// Copyright 2022 Google LLC
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

package projects

import (
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	"github.com/terraform-google-modules/terraform-google-enterprise-genai/test/integration/testutils"
)

func getNetworkMode(t *testing.T) string {
	mode := utils.ValFromEnv(t, "TF_VAR_example_foundations_mode")
	if mode == "HubAndSpoke" {
		return "-spoke"
	}
	return ""
}

func TestProjects(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	orgID := terraform.OutputMap(t, bootstrap.GetTFOptions(), "common_config")["org_id"]
	networkMode := getNetworkMode(t)
	policyID := testutils.GetOrgACMPolicyID(t, orgID)
	require.NotEmpty(t, policyID, "Access Context Manager Policy ID must be configured in the organization for the test to proceed.")

	// Configure impersonation for test execution
	terraformSA := bootstrap.GetStringOutput("projects_step_terraform_service_account_email")
	utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)

	projects_backend_bucket := bootstrap.GetStringOutput("projects_gcs_bucket_tfstate")
	backendConfig := map[string]interface{}{
		"bucket": projects_backend_bucket,
	}
	backend_bucket := bootstrap.GetStringOutput("gcs_bucket_tfstate")

	for _, tt := range []struct {
		name              string
		repo              string
		baseDir           string
		baseNetwork       string
		restrictedNetwork string
	}{
		{
			name:              "bu1_development",
			repo:              "bu1-example-app",
			baseNetwork:       fmt.Sprintf("vpc-d-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-d-shared-restricted%s", networkMode),
		},
		{
			name:              "bu1_non-production",
			repo:              "bu1-example-app",
			baseDir:           "../../../4-projects/business_unit_1/%s",
			baseNetwork:       fmt.Sprintf("vpc-n-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-n-shared-restricted%s", networkMode),
		},
		{
			name:              "bu1_production",
			repo:              "bu1-example-app",
			baseDir:           "../../../4-projects/business_unit_1/%s",
			baseNetwork:       fmt.Sprintf("vpc-p-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-p-shared-restricted%s", networkMode),
		},
		{
			name:              "bu2_development",
			repo:              "bu2-example-app",
			baseDir:           "../../../4-projects/business_unit_2/%s",
			baseNetwork:       fmt.Sprintf("vpc-d-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-d-shared-restricted%s", networkMode),
		},
		{
			name:              "bu2_non-production",
			repo:              "bu2-example-app",
			baseDir:           "../../../4-projects/business_unit_2/%s",
			baseNetwork:       fmt.Sprintf("vpc-n-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-n-shared-restricted%s", networkMode),
		},
		{
			name:              "bu2_production",
			repo:              "bu2-example-app",
			baseDir:           "../../../4-projects/business_unit_2/%s",
			baseNetwork:       fmt.Sprintf("vpc-p-shared-base%s", networkMode),
			restrictedNetwork: fmt.Sprintf("vpc-p-shared-restricted%s", networkMode),
		},
	} {
		t.Run(tt.name, func(t *testing.T) {

			env := testutils.GetLastSplitElement(tt.name, "_")

			vars := map[string]interface{}{
				"remote_state_bucket": backend_bucket,
			}

			projects := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf(tt.baseDir, env)),
				tft.WithVars(vars),
				tft.WithBackendConfig(backendConfig),
				tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
				tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
			)
			projects.Test()
		})

	}
}
