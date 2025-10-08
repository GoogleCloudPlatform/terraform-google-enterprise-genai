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

package bootstrap

import (
	"os"
	"os/exec"
	"path"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
)

// fileExists check if a give file exists
func fileExists(filePath string) (bool, error) {
	_, err := os.Stat(filePath)
	if err == nil {
		return true, nil
	}
	if os.IsNotExist(err) {
		return false, nil
	}
	return false, err
}

func TestBootstrap(t *testing.T) {

	vars := map[string]interface{}{
		"bucket_force_destroy":             true,
		"bucket_tfstate_kms_force_destroy": true,
	}

	temp := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
		tft.WithVars(vars),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
		tft.WithPolicyLibraryPath("/workspace/policy-library", temp.GetTFSetupStringOutput("project_id")),
	)

	bootstrap.DefineApply(
		func(assert *assert.Assertions) {
			// check APIs
			projectID := bootstrap.GetTFSetupStringOutput("project_id")
			for _, api := range []string{
				"cloudresourcemanager.googleapis.com",
				"cloudbilling.googleapis.com",
				"iam.googleapis.com",
				"storage-api.googleapis.com",
				"serviceusage.googleapis.com",
				"cloudbuild.googleapis.com",
				"sourcerepo.googleapis.com",
				"cloudkms.googleapis.com",
				"bigquery.googleapis.com",
				"accesscontextmanager.googleapis.com",
				"securitycenter.googleapis.com",
				"servicenetworking.googleapis.com",
				"billingbudgets.googleapis.com",
			} {
				utils.Poll(t, func() (bool, error) { return testutils.CheckAPIEnabled(t, projectID, api) }, 5, 2*time.Minute)
			}

			bootstrap.DefaultApply(assert)

			// configure options to push state to GCS bucket
			tempOptions := bootstrap.GetTFOptions()
			tempOptions.BackendConfig = map[string]interface{}{
				"bucket": bootstrap.GetStringOutput("gcs_bucket_tfstate"),
			}
			tempOptions.MigrateState = true
			// create backend file
			cwd, err := os.Getwd()
			require.NoError(t, err)
			destFile := path.Join(cwd, "../../../0-bootstrap/backend.tf")
			fExists, err2 := fileExists(destFile)
			require.NoError(t, err2)
			if !fExists {
				srcFile := path.Join(cwd, "../../../0-bootstrap/backend.tf.example")
				_, err3 := exec.Command("cp", srcFile, destFile).CombinedOutput()
				require.NoError(t, err3)
			}
			terraform.Init(t, tempOptions)
		})

	bootstrap.DefineTeardown(func(assert *assert.Assertions) {
		// configure options to pull state from GCS bucket
		cwd, err := os.Getwd()
		require.NoError(t, err)
		statePath := path.Join(cwd, "../../../0-bootstrap/local_backend.tfstate")
		tempOptions := bootstrap.GetTFOptions()
		tempOptions.BackendConfig = map[string]interface{}{
			"path": statePath,
		}
		tempOptions.MigrateState = true
		// remove backend file
		backendFile := path.Join(cwd, "../../../0-bootstrap/backend.tf")
		fExists, err2 := fileExists(backendFile)
		require.NoError(t, err2)
		if fExists {
			_, err3 := exec.Command("rm", backendFile).CombinedOutput()
			require.NoError(t, err3)
		}
		terraform.Init(t, tempOptions)
		bootstrap.DefaultTeardown(assert)
	})
	bootstrap.Test()
}
