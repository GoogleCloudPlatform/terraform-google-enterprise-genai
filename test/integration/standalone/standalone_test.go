/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package standalone

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"strings"
	"testing"
	"time"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/tft"
	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/utils"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// fileExists checks if a given file exists.
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

func TestStandalone(t *testing.T) {
	// VPC Service Controls variables.
	restrictedServices := []string{
		"serviceusage.googleapis.com",
		"essentialcontacts.googleapis.com",
		"accessapproval.googleapis.com",
		"adsdatahub.googleapis.com",
		"aiplatform.googleapis.com",
		"alloydb.googleapis.com",
		"documentai.googleapis.com",
		"analyticshub.googleapis.com",
		"apigee.googleapis.com",
		"apigeeconnect.googleapis.com",
		"artifactregistry.googleapis.com",
		"assuredworkloads.googleapis.com",
		"automl.googleapis.com",
		"baremetalsolution.googleapis.com",
		"batch.googleapis.com",
		"bigquery.googleapis.com",
		"bigquerydatapolicy.googleapis.com",
		"bigquerydatatransfer.googleapis.com",
		"bigquerymigration.googleapis.com",
		"bigqueryreservation.googleapis.com",
		"bigtable.googleapis.com",
		"binaryauthorization.googleapis.com",
		"cloud.googleapis.com",
		"cloudasset.googleapis.com",
		"cloudbuild.googleapis.com",
		"clouddebugger.googleapis.com",
		"clouddeploy.googleapis.com",
		"clouderrorreporting.googleapis.com",
		"cloudfunctions.googleapis.com",
		"cloudkms.googleapis.com",
		"cloudprofiler.googleapis.com",
		"cloudresourcemanager.googleapis.com",
		"cloudscheduler.googleapis.com",
		"cloudsearch.googleapis.com",
		"cloudtrace.googleapis.com",
		"composer.googleapis.com",
		"compute.googleapis.com",
		"connectgateway.googleapis.com",
		"contactcenterinsights.googleapis.com",
		"container.googleapis.com",
		"containeranalysis.googleapis.com",
		"containerfilesystem.googleapis.com",
		"containerregistry.googleapis.com",
		"containerthreatdetection.googleapis.com",
		"datacatalog.googleapis.com",
		"dataflow.googleapis.com",
		"datafusion.googleapis.com",
		"datamigration.googleapis.com",
		"dataplex.googleapis.com",
		"dataproc.googleapis.com",
		"datastream.googleapis.com",
		"dialogflow.googleapis.com",
		"dlp.googleapis.com",
		"dns.googleapis.com",
		"domains.googleapis.com",
		"eventarc.googleapis.com",
		"file.googleapis.com",
		"firebaseappcheck.googleapis.com",
		"firebaserules.googleapis.com",
		"firestore.googleapis.com",
		"gameservices.googleapis.com",
		"gkebackup.googleapis.com",
		"gkeconnect.googleapis.com",
		"gkehub.googleapis.com",
		"healthcare.googleapis.com",
		"iam.googleapis.com",
		"iamcredentials.googleapis.com",
		"iaptunnel.googleapis.com",
		"ids.googleapis.com",
		"integrations.googleapis.com",
		"kmsinventory.googleapis.com",
		"krmapihosting.googleapis.com",
		"language.googleapis.com",
		"lifesciences.googleapis.com",
		"logging.googleapis.com",
		"managedidentities.googleapis.com",
		"memcache.googleapis.com",
		"meshca.googleapis.com",
		"meshconfig.googleapis.com",
		"metastore.googleapis.com",
		"ml.googleapis.com",
		"monitoring.googleapis.com",
		"networkconnectivity.googleapis.com",
		"networkmanagement.googleapis.com",
		"networksecurity.googleapis.com",
		"networkservices.googleapis.com",
		"notebooks.googleapis.com",
		"opsconfigmonitoring.googleapis.com",
		"orgpolicy.googleapis.com",
		"osconfig.googleapis.com",
		"oslogin.googleapis.com",
		"privateca.googleapis.com",
		"pubsub.googleapis.com",
		"pubsublite.googleapis.com",
		"recaptchaenterprise.googleapis.com",
		"recommender.googleapis.com",
		"redis.googleapis.com",
		"retail.googleapis.com",
		"run.googleapis.com",
		"secretmanager.googleapis.com",
		"servicecontrol.googleapis.com",
		"servicedirectory.googleapis.com",
		"spanner.googleapis.com",
		"speakerid.googleapis.com",
		"speech.googleapis.com",
		"sqladmin.googleapis.com",
		"storage.googleapis.com",
		"storagetransfer.googleapis.com",
		"sts.googleapis.com",
		"texttospeech.googleapis.com",
		"timeseriesinsights.googleapis.com",
		"tpu.googleapis.com",
		"trafficdirector.googleapis.com",
		"transcoder.googleapis.com",
		"translate.googleapis.com",
		"videointelligence.googleapis.com",
		"vision.googleapis.com",
		"visionai.googleapis.com",
		"vmmigration.googleapis.com",
		"vpcaccess.googleapis.com",
		"webrisk.googleapis.com",
		"workflows.googleapis.com",
		"workstations.googleapis.com",
	}

	ingressPolicies := []map[string]interface{}{}
	egressPolicies := []map[string]interface{}{}

	temp := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/standalone"),
	)

	// Create Access Context Manager Policy ID if needed
	orgID := temp.GetTFSetupStringOutput("org_id")
	policyID := testutils.GetOrgACMPolicyID(t, orgID)
	terraformSA := temp.GetTFSetupStringOutput("terraform_service_account")

	if policyID == "" {
		_, err := gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies create --organization %s --title %s --impersonate-service-account %s", orgID, "defaultpolicy", terraformSA))
		// ignore creation error and proceed with the test
		if err != nil {
			fmt.Printf("Ignore error in creation of access-context-manager policy ID for organization %s. Error: [%s]", orgID, err.Error())
		}
	}

	vars := map[string]interface{}{
		"project_deletion_policy":          "DELETE",
		"kms_prevent_destroy":              false,
		"bucket_force_destroy":             true,
		"access_context_manager_policy_id": policyID,
		"ingress_policies":                 ingressPolicies,
		"egress_policies":                  egressPolicies,
		"perimeter_additional_members":     []string{},
	}

	// Standalone deployment.
	standalone := tft.NewTFBlueprintTest(t,
		tft.WithTFDir("../../../examples/standalone"),
		tft.WithVars(vars),
	)

	standalone.DefineApply(func(a *assert.Assertions) {
		// check APIs
		projectID := standalone.GetTFSetupStringOutput("project_id")
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
			"essentialcontacts.googleapis.com",
		} {
			utils.Poll(t, func() (bool, error) { return testutils.CheckAPIEnabled(t, projectID, api) }, 5, 2*time.Minute)
		}

		standalone.DefaultApply(a)

		//backend setup
		tempOptions := standalone.GetTFOptions()
		tempOptions.BackendConfig = map[string]interface{}{
			"bucket": standalone.GetStringOutput("state_bucket"),
		}
		tempOptions.MigrateState = true

		cwd, err := os.Getwd()
		require.NoError(t, err)

		backendFile := path.Join(cwd, "../../../examples/standalone/backend.tf")
		backendExists, err := fileExists(backendFile)
		require.NoError(t, err)

		if !backendExists {
			backendExampleFile := path.Join(cwd, "../../../examples/standalone/backend.tf.example")
			_, err := exec.Command("cp", backendExampleFile, backendFile).CombinedOutput()
			require.NoError(t, err)
		}

		terraform.Init(t, tempOptions)
	})

	standalone.DefineVerify(func(a *assert.Assertions) {
		standalone.DefaultVerify(a)

		terraformSA := standalone.GetStringOutput("terraform_service_account")
		orgID := standalone.GetTFSetupStringOutput("org_id")
		parentFolder := testutils.GetLastSplitElement(standalone.GetStringOutput("parent_resource_id"), "/")

		// Ensure ACM policy exists.
		policyID := testutils.GetOrgACMPolicyID(t, orgID)
		if policyID == "" {
			_, err := gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies create --organization %s --title defaultpolicy --impersonate-service-account %s", orgID, terraformSA))

			if err != nil {
				fmt.Printf("Ignore error in creation of access-context-manager policy ID for organization %s. Error: [%s]", orgID, err.Error())
			}

			policyID = testutils.GetOrgACMPolicyID(t, orgID)
		}

		// VPC Service Controls.
		servicePerimeterName := standalone.GetStringOutput("service_perimeter_name")
		servicePerimeterLink := fmt.Sprintf("accessPolicies/%s/servicePerimeters/%s", policyID, servicePerimeterName)
		accessLevel := fmt.Sprintf("accessPolicies/%s/accessLevels/%s", policyID, standalone.GetStringOutput("access_level_name_dry_run"))

		servicePerimeter, err := gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager perimeters describe %s --policy %s", servicePerimeterLink, policyID))
		a.NoError(err)

		a.True(strings.Contains(servicePerimeter, servicePerimeterName), fmt.Sprintf("service perimeter %s should exist", servicePerimeterName))

		a.True(strings.Contains(servicePerimeter, accessLevel), fmt.Sprintf("service perimeter %s should have access level %s", servicePerimeterLink, accessLevel))

		for _, service := range restrictedServices {
			a.True(strings.Contains(servicePerimeter, service), fmt.Sprintf("service perimeter %s should restrict service %s", servicePerimeterLink, service))
		}

		perimeter := gcloud.Runf(t, "access-context-manager perimeters describe %s --policy %s", servicePerimeterLink, policyID)
		perimeterResources := utils.GetResultStrSlice(perimeter.Get("spec.resources").Array())

		// Projects and APIs.
		for _, projectCheck := range []struct {
			projectOutput       string
			apis                []string
			shouldBeInPerimeter bool
		}{
			{
				projectOutput: "seed_project_id",
				apis: []string{
					"cloudkms.googleapis.com",
					"serviceusage.googleapis.com",
					"iamcredentials.googleapis.com",
					"storage.googleapis.com",
				},
				shouldBeInPerimeter: false,
			},
			{
				projectOutput: "logging_project_id",
				apis: []string{
					"bigquery.googleapis.com",
					"logging.googleapis.com",
					"billingbudgets.googleapis.com",
				},
				shouldBeInPerimeter: true,
			},
			{
				projectOutput: "kms_project_id",
				apis: []string{
					"cloudkms.googleapis.com",
					"logging.googleapis.com",
					"billingbudgets.googleapis.com",
				},
				shouldBeInPerimeter: true,
			},
			{
				projectOutput: "machine_learning_project_id",
				apis: []string{
					"aiplatform.googleapis.com",
					"artifactregistry.googleapis.com",
					"bigquery.googleapis.com",
					"bigquerymigration.googleapis.com",
					"bigquerystorage.googleapis.com",
					"cloudbuild.googleapis.com",
					"cloudkms.googleapis.com",
					"cloudresourcemanager.googleapis.com",
					"composer.googleapis.com",
					"compute.googleapis.com",
					"containerregistry.googleapis.com",
					"dataflow.googleapis.com",
					"dataform.googleapis.com",
					"deploymentmanager.googleapis.com",
					"iam.googleapis.com",
					"logging.googleapis.com",
					"notebooks.googleapis.com",
					"pubsub.googleapis.com",
					"secretmanager.googleapis.com",
					"serviceusage.googleapis.com",
					"storage-api.googleapis.com",
					"storage-component.googleapis.com",
					"storage.googleapis.com",
				},
				shouldBeInPerimeter: true,
			},
			{
				projectOutput: "service_catalog_project_id",
				apis: []string{
					"logging.googleapis.com",
					"storage.googleapis.com",
					"serviceusage.googleapis.com",
					"secretmanager.googleapis.com",
					"cloudbuild.googleapis.com",
					"cloudresourcemanager.googleapis.com",
					"sourcerepo.googleapis.com",
				},
				shouldBeInPerimeter: false,
			},
			{
				projectOutput: "artifact_publish_project_id",
				apis: []string{
					"artifactregistry.googleapis.com",
					"logging.googleapis.com",
					"billingbudgets.googleapis.com",
					"serviceusage.googleapis.com",
					"storage.googleapis.com",
					"cloudbuild.googleapis.com",
					"secretmanager.googleapis.com",
					"sourcerepo.googleapis.com",
				},
				shouldBeInPerimeter: false,
			},
		} {
			projectID := standalone.GetStringOutput(projectCheck.projectOutput)
			prj := gcloud.Runf(t, "projects describe %s", projectID)

			projectNumber := prj.Get("projectNumber").String()

			a.Equal(projectID, prj.Get("projectId").String(), fmt.Sprintf("project %s should exist", projectID))
			a.Equal("ACTIVE", prj.Get("lifecycleState").String(), fmt.Sprintf("project %s should be ACTIVE", projectID))

			enabledAPIs := gcloud.Runf(t, "services list --project %s", projectID).Array()
			listAPIs := testutils.GetResultFieldStrSlice(enabledAPIs, "config.name")
			a.Subset(listAPIs, projectCheck.apis, "APIs should have been enabled")

			expectedProjectResource := fmt.Sprintf("projects/%s", projectNumber)

			if projectCheck.shouldBeInPerimeter {
				a.Contains(perimeterResources, expectedProjectResource, fmt.Sprintf("project %s should be in the perimeter", projectID))
			} else {
				a.NotContains(perimeterResources, expectedProjectResource, fmt.Sprintf("project %s should not be in the perimeter", projectID))
			}
		}

		// KMS keyrings.
		kmsProjectID := standalone.GetStringOutput("kms_project_id")
		kmsLocations := terraform.OutputList(t, standalone.GetTFOptions(), "keyrings_regions")
		kmsKeyrings := terraform.OutputMap(t, standalone.GetTFOptions(), "kms_keyrings")

		for _, location := range kmsLocations {
			kmsKeyringID := kmsKeyrings[location]
			kmsKeyringName := path.Base(kmsKeyringID)

			resp := gcloud.Runf(t, "kms keyrings describe %s --location %s --project %s", kmsKeyringName, location, kmsProjectID)
			expected := fmt.Sprintf("projects/%s/locations/%s/keyRings/%s", kmsProjectID, location, kmsKeyringName)
			a.Equal(expected, resp.Get("name").String(), "KMS keyring should exist")
		}

		// KMS crypto keys.
		kmsKeys := terraform.OutputMapOfObjects(t, standalone.GetTFOptions(), "kms_keys")

		for location, locVal := range kmsKeys {
			keysMap := locVal.(map[string]interface{})

			for keyAlias, cryptoKeyIDRaw := range keysMap {
				cryptoKeyID := cryptoKeyIDRaw.(string)

				parts := strings.Split(cryptoKeyID, "/")
				if len(parts) < 8 {
					t.Fatalf("invalid crypto key id for location %s alias %s: %s", location, keyAlias, cryptoKeyID)
				}

				keyProjectID := parts[1]
				keyLocation := parts[3]
				keyringName := parts[5]
				cryptoKeyName := parts[7]

				resp := gcloud.Runf(t, "kms keys describe %s --keyring %s --location %s --project %s", cryptoKeyName, keyringName, keyLocation, keyProjectID)
				expected := fmt.Sprintf("projects/%s/locations/%s/keyRings/%s/cryptoKeys/%s", keyProjectID, keyLocation, keyringName, cryptoKeyName)
				a.Equal(expected, resp.Get("name").String(), "KMS crypto key should exist for location %s alias %s", location, keyAlias)
			}
		}

		// DNS.
		zones := map[string]string{
			"dz-shared-restricted-notebooks":                   "notebooks.cloud.google.com.",
			"dz-shared-restricted-notebooks-googleusercontent": "notebooks.googleusercontent.com.",
			"dz-shared-restricted-kernels-googleusercontent":   "kernels.googleusercontent.com.",
		}

		mlProjectID := standalone.GetStringOutput("machine_learning_project_id")

		for name := range zones {
			z := gcloud.Runf(t, "dns managed-zones describe %s --project %s", name, mlProjectID)
			a.Equal(name, z.Get("name").String())
		}

		// Boolean organization policies.
		for _, booleanConstraint := range []string{
			"constraints/ainotebooks.disableFileDownloads",
			"constraints/ainotebooks.disableRootAccess",
			"constraints/ainotebooks.disableTerminal",
			"constraints/ainotebooks.restrictPublicIp",
			"constraints/ainotebooks.requireAutoUpgradeSchedule",
			"constraints/cloudfunctions.requireVPCConnector",
		} {
			orgPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", booleanConstraint, parentFolder)

			a.True(orgPolicy.Get("booleanPolicy.enforced").Bool(), fmt.Sprintf("org policy %s should be enforced", booleanConstraint))
		}

		// Cloud Build allowed integrations.
		cloudBuildAllowedIntegrationsPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/cloudbuild.allowedIntegrations", parentFolder)

		for _, allowedIntegration := range []string{
			"github.com",
			"source.developers.google.com",
		} {
			a.Contains(utils.GetResultStrSlice(cloudBuildAllowedIntegrationsPolicy.Get("listPolicy.allowedValues").Array()), allowedIntegration, fmt.Sprintf("org policy should contain allowed integration %s", allowedIntegration))
		}

		// Allowed locations.
		allowedLocationsPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/gcp.resourceLocations", parentFolder)

		a.Contains(utils.GetResultStrSlice(allowedLocationsPolicy.Get("listPolicy.allowedValues").Array()), "in:us-locations")

		// Restrict VPC networks.
		restrictVpcNetworksPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/ainotebooks.restrictVpcNetworks", parentFolder)

		a.Contains(utils.GetResultStrSlice(restrictVpcNetworksPolicy.Get("listPolicy.allowedValues").Array()), fmt.Sprintf("under:projects/%s", standalone.GetStringOutput("machine_learning_project_id")))

		// Restrict service usage.
		restrictServiceUsagePolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/gcp.restrictServiceUsage", parentFolder)

		a.Contains(utils.GetResultStrSlice(restrictServiceUsagePolicy.Get("listPolicy.deniedValues").Array()), "alloydb.googleapis.com")

		// Deny restricted TLS versions.
		restrictTLSVersionPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/gcp.restrictTLSVersion", parentFolder)

		for _, restrictedTLSVersion := range []string{
			"TLS_VERSION_1",
			"TLS_VERSION_1_1",
		} {
			a.Contains(utils.GetResultStrSlice(restrictTLSVersionPolicy.Get("listPolicy.deniedValues").Array()), restrictedTLSVersion, fmt.Sprintf("org policy should contain denied TLS version %s", restrictedTLSVersion))
		}

		// Restricted CMEK services.
		restrictNonCmekServicesPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/gcp.restrictNonCmekServices", parentFolder)

		for _, restrictedCmekService := range []string{
			"bigquery.googleapis.com",
			"aiplatform.googleapis.com",
		} {
			a.Contains(utils.GetResultStrSlice(restrictNonCmekServicesPolicy.Get("listPolicy.deniedValues").Array()), restrictedCmekService)
		}

		// Allowed Vertex access modes.
		vertexAccessModePolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/ainotebooks.accessMode", parentFolder)

		for _, allowedVertexAccessMode := range []string{
			"single-user",
			"service-account",
		} {
			a.Contains(utils.GetResultStrSlice(vertexAccessModePolicy.Get("listPolicy.allowedValues").Array()), allowedVertexAccessMode)
		}

		// Vertex AI allowed images.
		vertexEnvironmentOptionsPolicy := gcloud.Runf(t, "resource-manager org-policies describe %s --folder %s", "constraints/ainotebooks.environmentOptions", parentFolder)

		for _, vertexAIAllowedImage := range []string{
			"ainotebooks-vm/deeplearning-platform-release/image-family/pytorch-1-13-cu113-notebooks",
			"ainotebooks-vm/deeplearning-platform-release/image-family/common-cu113-notebooks",
			"ainotebooks-vm/deeplearning-platform-release/image-family/common-cpu-notebooks",
			"ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py310",
			"ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu113.py37",
			"ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/base-cu110.py310",
			"ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-cpu.2-12.py310",
			"ainotebooks-container/us-docker.pkg.dev/deeplearning-platform-release/gcr.io/tf2-gpu.2-12.py310",
		} {
			a.Contains(utils.GetResultStrSlice(vertexEnvironmentOptionsPolicy.Get("listPolicy.allowedValues").Array()), vertexAIAllowedImage)
		}

		// Log bucket.
		logBucket := standalone.GetStringOutput("log_bucket")
		loggingProjectID := standalone.GetStringOutput("logging_project_id")
		gcAlphaOpts := gcloud.WithCommonArgs([]string{"--project", loggingProjectID, "--json"})

		bkt := gcloud.Run(t, fmt.Sprintf("alpha storage ls --buckets gs://%s", logBucket), gcAlphaOpts).Array()[0]
		a.Equal(logBucket, bkt.Get("metadata.id").String(), fmt.Sprintf("Bucket %s should exist", logBucket))

		// Network.
		networkName := standalone.GetStringOutput("machine_learning_network_name")
		expectedNetworkSelfLink := standalone.GetStringOutput("restricted_network_self_link")

		projectNetwork := gcloud.Runf(t, "compute networks describe %s --project %s --impersonate-service-account %s", networkName, mlProjectID, terraformSA)

		a.Equal(networkName, projectNetwork.Get("name").String(), fmt.Sprintf("network %s should exist", networkName))
		a.Equal(expectedNetworkSelfLink, projectNetwork.Get("selfLink").String(), fmt.Sprintf("network self_link should be %s", expectedNetworkSelfLink))

		// Subnetworks self-links.
		subnets := terraform.OutputList(t, standalone.GetTFOptions(), "machine_learning_subnets_self_link")
		a.NotEmpty(subnets, "Machine learning subnets self-links list should not be empty")

		for _, subnetLink := range subnets {
			parts := strings.Split(subnetLink, "/")
			if len(parts) >= 4 {
				subnetName := parts[len(parts)-1]
				region := parts[len(parts)-3]
				subnetDesc := gcloud.Runf(t, "compute networks subnets describe %s --region %s --project %s --impersonate-service-account %s", subnetName, region, mlProjectID, terraformSA)
				a.Equal(subnetName, subnetDesc.Get("name").String(), fmt.Sprintf("subnet %s should exist in region %s", subnetName, region))
				a.Equal(subnetLink, subnetDesc.Get("selfLink").String(), fmt.Sprintf("subnet self link should be %s", subnetLink))
			}
		}

		// Firewall egress rule.
		allowEgressName := "fw-1000-e-a-all-all-all"

		allowEgressRule := gcloud.Runf(t, "compute firewall-rules describe %s --project %s --impersonate-service-account %s", allowEgressName, mlProjectID, terraformSA)

		a.Equal(allowEgressName, allowEgressRule.Get("name").String(), fmt.Sprintf("firewall rule %s should exist", allowEgressName))
		a.Equal("EGRESS", allowEgressRule.Get("direction").String(), fmt.Sprintf("firewall rule %s direction should be EGRESS", allowEgressName))
		a.Equal(int64(1000), allowEgressRule.Get("priority").Int(), fmt.Sprintf("firewall rule %s priority should be 1000", allowEgressName))
		a.Equal("all", allowEgressRule.Get("allowed").Array()[0].Get("IPProtocol").String(), fmt.Sprintf("firewall rule %s should allow all protocols", allowEgressName))
		a.Equal("0.0.0.0/0", allowEgressRule.Get("destinationRanges").Array()[0].String(), fmt.Sprintf("firewall rule %s destination ranges should be 0.0.0.0/0", allowEgressName))
		a.Equal("INCLUDE_ALL_METADATA", allowEgressRule.Get("logConfig.metadata").String(), fmt.Sprintf("firewall rule %s should have log configuration enabled", allowEgressName))

		// Firewall ingress rule.
		rawIngressRanges := standalone.GetStringOutput("allow_ingress_firewall_rule_ip_range")
		rawIngressRanges = strings.Trim(rawIngressRanges, "[]")
		allowIngressRuleIPRanges := strings.Fields(rawIngressRanges)

		allowIngressName := "fw-shared-base-1000-i-a-all"
		fwArgs := gcloud.WithCommonArgs([]string{"--project", mlProjectID, "--impersonate-service-account", terraformSA, "--format=json"})

		allowIngressRule := gcloud.Run(t, fmt.Sprintf("compute firewall-rules describe %s", allowIngressName), fwArgs)

		a.Equal(allowIngressName, allowIngressRule.Get("name").String(), fmt.Sprintf("firewall rule %s should exist", allowIngressName))
		a.Equal("INGRESS", allowIngressRule.Get("direction").String(), fmt.Sprintf("firewall rule %s direction should be INGRESS", allowIngressName))
		a.Equal(int64(1000), allowIngressRule.Get("priority").Int(), fmt.Sprintf("firewall rule %s priority should be 1000", allowIngressName))
		a.Equal("all", allowIngressRule.Get("allowed").Array()[0].Get("IPProtocol").String(), fmt.Sprintf("firewall rule %s should allow all protocols", allowIngressName))

		actualIngressRanges := []string{}
		for _, r := range allowIngressRule.Get("sourceRanges").Array() {
			actualIngressRanges = append(actualIngressRanges, r.String())
		}

		a.ElementsMatch(allowIngressRuleIPRanges, actualIngressRanges, fmt.Sprintf("firewall rule %s source ranges should match expected ranges", allowIngressName))

		// Service Catalog repository and Cloud Build trigger.
		serviceCatalogProjectID := standalone.GetStringOutput("service_catalog_project_id")
		serviceCatalogRepoID := standalone.GetStringOutput("service_catalog_repo_id")
		serviceCatalogRepoName := testutils.GetLastSplitElement(serviceCatalogRepoID, "/")

		serviceCatalogRepo := gcloud.Runf(t, "source repos describe %s --project %s --impersonate-service-account %s", serviceCatalogRepoName, serviceCatalogProjectID, terraformSA)

		a.Equal(serviceCatalogRepoID, serviceCatalogRepo.Get("name").String(), "Service Catalog repository should exist")

		serviceCatalogTriggerID := standalone.GetStringOutput("service_catalog_cloudbuild_trigger_id")
		a.NotEmpty(serviceCatalogTriggerID, "Service Catalog Cloud Build trigger ID should exist and not be empty")

		serviceCatalogTrigger := gcloud.Runf(t, "builds triggers describe %s --project %s --region %s --impersonate-service-account %s", serviceCatalogTriggerID, serviceCatalogProjectID, "global", terraformSA)

		a.Equal(serviceCatalogTriggerID, serviceCatalogTrigger.Get("id").String(), "Service Catalog Cloud Build trigger should exist in GCP")

		// Artifact Publish repository and Cloud Build trigger.
		artifactProjectID := standalone.GetStringOutput("artifact_publish_project_id")
		artifactRepoID := standalone.GetStringOutput("artifacts_repo_id")
		artifactRepoName := testutils.GetLastSplitElement(artifactRepoID, "/")

		artifactRepo := gcloud.Runf(t, "source repos describe %s --project %s --impersonate-service-account %s", artifactRepoName, artifactProjectID, terraformSA)

		a.Equal(artifactRepoID, artifactRepo.Get("name").String(), "Artifact Publish repository should exist")

		artifactTriggerID := standalone.GetStringOutput("artifact_publish_cloudbuild_trigger_id")
		a.NotEmpty(artifactTriggerID, "Artifact Publish Cloud Build trigger ID should exist and not be empty")

		artifactTrigger := gcloud.Runf(t, "builds triggers describe %s --project %s --region %s --impersonate-service-account %s", artifactTriggerID, artifactProjectID, "global", terraformSA)

		a.Equal(artifactTriggerID, artifactTrigger.Get("id").String(), "Artifact Publish Cloud Build trigger should exist in GCP")
	})

	standalone.DefineTeardown(func(a *assert.Assertions) {
		cwd, err := os.Getwd()
		require.NoError(t, err)

		statePath := path.Join(cwd, "../../../examples/standalone/local_backend.tfstate")

		tempOptions := standalone.GetTFOptions()
		tempOptions.BackendConfig = map[string]interface{}{
			"path": statePath,
		}
		tempOptions.MigrateState = true

		backendFile := path.Join(cwd, "../../../examples/standalone/backend.tf")
		backendExists, err := fileExists(backendFile)
		require.NoError(t, err)

		if backendExists {
			_, err := exec.Command("rm", backendFile).CombinedOutput()
			require.NoError(t, err)
		}

		terraform.Init(t, tempOptions)
		standalone.DefaultTeardown(a)
	})

	standalone.Test()
}
