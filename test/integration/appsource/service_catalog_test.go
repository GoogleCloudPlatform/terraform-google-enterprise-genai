// Copyright 2025 Google LLC
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

package appsource

import (
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/git"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
	"github.com/stretchr/testify/assert"

	cp "github.com/otiai10/copy"
)

func TestServiceCatalogSource(t *testing.T) {
	shared := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../4-projects/ml_business_unit/shared"),
	)

	serviceCatalogProject := shared.GetStringOutput("service_catalog_project_id")
	serviceCatalogPath := ("../../../5-app-infra/source_repos/service-catalog")
	serviceCaralogRepo := fmt.Sprintf("https://source.developers.google.com/p/%s/r/service-catalog", serviceCatalogProject)

	tmpDir := t.TempDir()
	if err := cp.Copy(serviceCatalogPath, tmpDir); err != nil {
		t.Fatal(err)
	}

	region := "us-central1"

	appsource := tft.NewTFBlueprintTest(t,
		tft.WithTFDir(serviceCatalogPath),
		tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 3, 2*time.Minute),
	)

	// Note:
	// The Git operations (repository initialization, commit, and push) are placed
	// inside DefineVerify() because they are functional integration steps rather than
	// Terraform-managed infrastructure. This section handles copying directories and
	// pushing content to a Cloud Source Repository to trigger Cloud Build pipelines.

	appsource.DefineVerify(func(assert *assert.Assertions) {

		//Push service catalog img and modules
		gitApp := git.NewCmdConfig(t, git.WithDir(tmpDir))
		gitAppRun := func(args ...string) {
			_, err := gitApp.RunCmdE(args...)
			if err != nil {
				t.Fatal(err)
			}
		}

		gitAppRun("init")
		gitAppRun("config", "user.email", "robot@example.com")
		gitAppRun("config", "user.name", "Test Robot")
		gitAppRun("config", "credential.https://source.developers.google.com.helper", "gcloud.sh")
		gitAppRun("checkout", "-b", "main")

		gitAppRun("remote", "add", "google", serviceCaralogRepo)

		gitAppRun("add", "img")
		gitApp.CommitWithMsg("Add img directory", nil)

		gitAppRun("add", "modules")
		gitApp.CommitWithMsg("Initialize Service Catalog Build Repo", nil)

		gitAppRun("push", "--all", "google", "-f")

		lastCommit := gitApp.GetLatestCommit()
		// filter builds triggered based on pushed commit sha
		buildListCmd := fmt.Sprintf("builds list --region=%s --filter substitutions.COMMIT_SHA='%s' --project %s", region, lastCommit, serviceCatalogProject)
		// poll build until complete

		pollCloudBuild := func(cmd string) func() (bool, error) {
			return func() (bool, error) {
				build := gcloud.Runf(t, cmd).Array()
				if len(build) < 1 {
					return true, nil
				}

				latestWorkflowRunStatus := build[0].Get("status").String()
				if latestWorkflowRunStatus == "SUCCESS" {
					return false, nil
				} else if latestWorkflowRunStatus == "FAILURE" {
					return false, errors.New("Build failed.")
				}
				return true, nil
			}
		}
		utils.Poll(t, pollCloudBuild(buildListCmd), 40, 30*time.Second)
	})
	appsource.Test()
}
