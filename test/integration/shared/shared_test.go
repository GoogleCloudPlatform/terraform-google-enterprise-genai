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

package shared

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
)

func TestShared(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	orgID := terraform.OutputMap(t, bootstrap.GetTFOptions(), "common_config")["org_id"]
	policyID := testutils.GetOrgACMPolicyID(t, orgID)
	require.NotEmpty(t, policyID, "Access Context Manager Policy ID must be configured in the organization for the test to proceed.")

	// Configure impersonation for test execution
	terraformSA := bootstrap.GetStringOutput("networks_step_terraform_service_account_email")
	utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)
	backend_bucket := bootstrap.GetStringOutput("gcs_bucket_tfstate")

	backendConfig := map[string]interface{}{
		"bucket": backend_bucket,
	}

	vars := map[string]interface{}{
		"remote_state_bucket": backend_bucket,
	}

	shared := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../3-networks-dual-svpc/envs/shared"),
		tft.WithVars(vars),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
		tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
		tft.WithBackendConfig(backendConfig),
	)
	shared.DefineVerify(
		func(assert *assert.Assertions) {

			// perform default verification ensuring Terraform reports no additional changes on an applied blueprint
			shared.DefaultVerify(assert)
		})
	shared.Test()
}
