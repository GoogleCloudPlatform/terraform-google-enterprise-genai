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

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
)

func TestProjects(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	orgID := terraform.OutputMap(t, bootstrap.GetTFOptions(), "common_config")["org_id"]
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
			name:              "ml_development",
			repo:              "ml-machine-learning",
			baseDir:           "../../../4-projects/ml_business_unit/%s",
			baseNetwork:       "vpc-d-shared-base",
			restrictedNetwork: "vpc-d-shared-restricted",
		},
		{
			name:              "ml_non-production",
			repo:              "ml-machine-learning",
			baseDir:           "../../../4-projects/ml_business_unit/%s",
			baseNetwork:       "vpc-n-shared-base",
			restrictedNetwork: "vpc-n-shared-restricted",
		},
		{
			name:              "ml_production",
			repo:              "ml-machine-learning",
			baseDir:           "../../../4-projects/ml_business_unit/%s",
			baseNetwork:       "vpc-p-shared-base",
			restrictedNetwork: "vpc-p-shared-restricted",
		},
	} {
		t.Run(tt.name, func(t *testing.T) {

			env := testutils.GetLastSplitElement(tt.name, "_")

			vars := map[string]interface{}{
				"remote_state_bucket": backend_bucket,
				"env":                 env,
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
