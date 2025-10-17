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

package projectsshared

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
)

func TestProjectsShared(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	// Configure impersonation for test execution
	terraformSA := bootstrap.GetStringOutput("projects_step_terraform_service_account_email")
	utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)

	backend_bucket := bootstrap.GetStringOutput("gcs_bucket_tfstate")
	projects_backend_bucket := bootstrap.GetStringOutput("projects_gcs_bucket_tfstate")
	backendConfig := map[string]interface{}{
		"bucket": projects_backend_bucket,
	}

	sharedVars := map[string]interface{}{
		"remote_state_bucket":     backend_bucket,
		"prevent_destroy":         false,
		"project_deletion_policy": "DELETE",
	}

	shared := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../4-projects/ml_business_unit/shared"),
		tft.WithVars(sharedVars),
		tft.WithBackendConfig(backendConfig),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
		tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
	)
	shared.DefineVerify(
		func(assert *assert.Assertions) {
			shared.DefaultVerify(assert)
		})
	shared.Test()
}
