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

package networks

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

func getNetworkMode(t *testing.T) string {
	mode := utils.ValFromEnv(t, "TF_VAR_example_foundations_mode")
	if mode == "HubAndSpoke" {
		return "-spoke"
	}
	return ""
}

func getNetworkResourceNames(envCode string, networkMode string) map[string]map[string]string {
	return map[string]map[string]string{
		"base": {
			"network_name":          fmt.Sprintf("vpc-%s-shared-base%s", envCode, networkMode),
			"global_address":        fmt.Sprintf("ga-%s-shared-base%s-vpc-peering-internal", envCode, networkMode),
			"dns_zone_googleapis":   fmt.Sprintf("dz-%s-shared-base-apis", envCode),
			"dns_zone_gcr":          fmt.Sprintf("dz-%s-shared-base-gcr", envCode),
			"dns_zone_pkg_dev":      fmt.Sprintf("dz-%s-shared-base-pkg-dev", envCode),
			"dns_zone_peering_zone": fmt.Sprintf("dz-%s-shared-base-to-dns-hub", envCode),
			"dns_policy_name":       fmt.Sprintf("dp-%s-shared-base-default-policy", envCode),
			"subnet_name1":          fmt.Sprintf("sb-%s-shared-base-us-west1", envCode),
			"subnet_name2":          fmt.Sprintf("sb-%s-shared-base-us-central1", envCode),
			"region1_router1":       fmt.Sprintf("cr-%s-shared-base%s-us-west1-cr1", envCode, networkMode),
			"region1_router2":       fmt.Sprintf("cr-%s-shared-base%s-us-west1-cr2", envCode, networkMode),
			"region2_router1":       fmt.Sprintf("cr-%s-shared-base%s-us-central1-cr3", envCode, networkMode),
			"region2_router2":       fmt.Sprintf("cr-%s-shared-base%s-us-central1-cr4", envCode, networkMode),
			"fw_deny_all_egress":    fmt.Sprintf("fw-%s-shared-base-65530-e-d-all-all-all", envCode),
			"fw_allow_api_egress":   fmt.Sprintf("fw-%s-shared-base-65430-e-a-allow-google-apis-all-tcp-443", envCode),
		},
		"restricted": {
			"network_name":          fmt.Sprintf("vpc-%s-shared-restricted%s", envCode, networkMode),
			"global_address":        fmt.Sprintf("ga-%s-shared-restricted%s-vpc-peering-internal", envCode, networkMode),
			"dns_zone_googleapis":   fmt.Sprintf("dz-%s-shared-restricted-apis", envCode),
			"dns_zone_gcr":          fmt.Sprintf("dz-%s-shared-restricted-gcr", envCode),
			"dns_zone_pkg_dev":      fmt.Sprintf("dz-%s-shared-restricted-pkg-dev", envCode),
			"dns_zone_peering_zone": fmt.Sprintf("dz-%s-shared-restricted-to-dns-hub", envCode),
			"dns_policy_name":       fmt.Sprintf("dp-%s-shared-restricted-default-policy", envCode),
			"subnet_name1":          fmt.Sprintf("sb-%s-shared-restricted-us-west1", envCode),
			"subnet_name2":          fmt.Sprintf("sb-%s-shared-restricted-us-central1", envCode),
			"region1_router1":       fmt.Sprintf("cr-%s-shared-restricted%s-us-west1-cr5", envCode, networkMode),
			"region1_router2":       fmt.Sprintf("cr-%s-shared-restricted%s-us-west1-cr6", envCode, networkMode),
			"region2_router1":       fmt.Sprintf("cr-%s-shared-restricted%s-us-central1-cr7", envCode, networkMode),
			"region2_router2":       fmt.Sprintf("cr-%s-shared-restricted%s-us-central1-cr8", envCode, networkMode),
			"fw_deny_all_egress":    fmt.Sprintf("fw-%s-shared-restricted-65530-e-d-all-all-all", envCode),
			"fw_allow_api_egress":   fmt.Sprintf("fw-%s-shared-restricted-65430-e-a-allow-google-apis-all-tcp-443", envCode),
		},
	}
}

func TestNetworks(t *testing.T) {

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

	ingressPolicies := []map[string]interface{}{
		{
			"from": map[string]interface{}{
				"sources": map[string][]string{
					"access_levels": {"*"},
				},
				"identity_type": "ANY_IDENTITY",
			},
			"to": map[string]interface{}{
				"resources": []string{"*"},
				"operations": map[string]map[string][]string{
					"storage.googleapis.com": {
						"methods": {
							"google.storage.objects.get",
							"google.storage.objects.list",
						},
					},
				},
			},
		},
	}

	egressPolicies := []map[string]interface{}{
		{
			"from": map[string]interface{}{
				"identity_type": "ANY_IDENTITY",
			},
			"to": map[string]interface{}{
				"resources": []string{"*"},
				"operations": map[string]map[string][]string{
					"storage.googleapis.com": {
						"methods": {
							"google.storage.objects.get",
							"google.storage.objects.list",
						},
					},
				},
			},
		},
	}

	for _, envName := range []string{
		"development",
		"non-production",
		"production",
	} {
		t.Run(envName, func(t *testing.T) {

			vars := map[string]interface{}{
				"access_context_manager_policy_id": policyID,
				"remote_state_bucket":              backend_bucket,
				"ingress_policies":                 ingressPolicies,
				"egress_policies":                  egressPolicies,
				"perimeter_additional_members":     []string{},
			}

			networks := tft.NewTFBlueprintTest(t,
				tft.WithTFDir(fmt.Sprintf("../../../3-networks-dual-svpc/envs/%s", envName)),
				tft.WithVars(vars),
				tft.WithRetryableTerraformErrors(testutils.RetryableTransientErrors, 1, 2*time.Minute),
				tft.WithPolicyLibraryPath("/workspace/policy-library", bootstrap.GetTFSetupStringOutput("project_id")),
				tft.WithBackendConfig(backendConfig),
			)
			networks.Test()
		})

	}
}
