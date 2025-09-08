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

package org

import (
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/stretchr/testify/assert"

	"github.com/terraform-google-modules/terraform-google-enterprise-genai/test/integration/testutils"
)

func TestOrg(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	backend_bucket := bootstrap.GetStringOutput("gcs_bucket_tfstate")

	vars := map[string]interface{}{
		"remote_state_bucket":              backend_bucket,
		"log_export_storage_force_destroy": "true",
		"cai_monitoring_kms_force_destroy": "true",
	}

	backendConfig := map[string]interface{}{
		"bucket": backend_bucket,
	}

	// Configure impersonation for test execution
	terraformSA := bootstrap.GetStringOutput("organization_step_terraform_service_account_email")
	utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)

	org := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../1-org/envs/shared"),
		tft.WithVars(vars),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
		tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
		tft.WithBackendConfig(backendConfig),
	)

	org.DefineApply(
		func(assert *assert.Assertions) {
			projectID := bootstrap.GetStringOutput("seed_project_id")
			for _, api := range []string{
				"serviceusage.googleapis.com",
				"servicenetworking.googleapis.com",
				"cloudkms.googleapis.com",
				"compute.googleapis.com",
				"logging.googleapis.com",
				"bigquery.googleapis.com",
				"cloudresourcemanager.googleapis.com",
				"cloudbilling.googleapis.com",
				"cloudbuild.googleapis.com",
				"iam.googleapis.com",
				"admin.googleapis.com",
				"appengine.googleapis.com",
				"storage-api.googleapis.com",
				"monitoring.googleapis.com",
				"pubsub.googleapis.com",
				"securitycenter.googleapis.com",
				"accesscontextmanager.googleapis.com",
				"billingbudgets.googleapis.com",
				"essentialcontacts.googleapis.com",
			} {
				utils.Poll(t, func() (bool, error) { return testutils.CheckAPIEnabled(t, projectID, api) }, 5, 2*time.Minute)
			}

			org.DefaultApply(assert)
		})
	org.Test()
}
