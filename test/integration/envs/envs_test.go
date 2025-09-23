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

package envs

import (
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"

	"github.com/terraform-google-modules/terraform-google-enterprise-genai/test/integration/testutils"
)

func TestEnvs(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	// Configure impersonation for test execution
	terraformSA := bootstrap.GetStringOutput("environment_step_terraform_service_account_email")
	utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)

	backend_bucket := bootstrap.GetStringOutput("gcs_bucket_tfstate")
	monitoringWorkspaceUsers := bootstrap.GetTFSetupStringOutput("monitoring_workspace_users")

	vars := map[string]interface{}{
		"remote_state_bucket":        backend_bucket,
		"monitoring_workspace_users": monitoringWorkspaceUsers,
		"kms_prevent_destroy":        false,
	}

	backendConfig := map[string]interface{}{
		"bucket": backend_bucket,
	}

	for _, envName := range []string{
		"development",
		"non-production",
		"production",
	} {
		t.Run(envName, func(t *testing.T) {
			envs := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf("../../../2-environments/envs/%s", envName)),
				tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
				tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
				tft.WithVars(vars),
				tft.WithBackendConfig(backendConfig),
			)
			envs.Test()
		})

	}
}
