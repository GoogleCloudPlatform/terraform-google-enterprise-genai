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

package appinfra

import (
	"fmt"
	"testing"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAppInfra(t *testing.T) {

	bootstrap := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../0-bootstrap"),
	)

	org := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../1-org/envs/shared"))

	projects_backend_bucket := bootstrap.GetStringOutput("projects_gcs_bucket_tfstate")
	log_bucket := org.GetStringOutput("logs_export_storage_bucket_name")

	vars := map[string]interface{}{
		"remote_state_bucket": projects_backend_bucket,
		"instance_region":     "us-central1",
	}

	shared := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../4-projects/ml_business_unit/shared"),
	)

	for _, projectName := range []string{
		"artifact-publish",
		"service-catalog",
	} {
		if projectName == "service-catalog" {
			vars["log_bucket"] = log_bucket
		}

		t.Run(projectName, func(t *testing.T) {
			terraformSA := terraform.OutputMap(t, shared.GetTFOptions(), "terraform_service_accounts")[fmt.Sprintf("ml-%s", projectName)]
			backend_bucket := terraform.OutputMap(t, shared.GetTFOptions(), "state_buckets")[fmt.Sprintf("ml-%s", projectName)]
			utils.SetEnv(t, "GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", terraformSA)
			backendConfig := map[string]interface{}{
				"bucket": backend_bucket,
			}

			appInfra := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf("../../../5-app-infra/projects/%s/ml_business_unit/shared/", projectName)),
				tft.WithBackendConfig(backendConfig),
				tft.WithVars(vars),
			)
			appInfra.Test()
		})
	}
}
