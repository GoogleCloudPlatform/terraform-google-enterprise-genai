// Copyright 2023 Google LLC
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

package stages

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/mitchellh/go-testing-interface"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/helpers/genai-deployer/gcp"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/helpers/genai-deployer/msg"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/helpers/genai-deployer/steps"
	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/helpers/genai-deployer/utils"

	"github.com/GoogleCloudPlatform/terraform-google-enterprise-genai/test/integration/testutils"
)

func DeployBootstrapStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, c CommonConf) error {
	bootstrapTfvars := BootstrapTfvars{
		OrgID:                        tfvars.OrgID,
		DefaultRegion:                tfvars.DefaultRegion,
		BillingAccount:               tfvars.BillingAccount,
		GroupOrgAdmins:               tfvars.GroupOrgAdmins,
		GroupBillingAdmins:           tfvars.GroupBillingAdmins,
		ParentFolder:                 tfvars.ParentFolder,
		ProjectPrefix:                tfvars.ProjectPrefix,
		FolderPrefix:                 tfvars.FolderPrefix,
		BucketForceDestroy:           tfvars.BucketForceDestroy,
		BucketTfstateKmsForceDestroy: tfvars.BucketTfstateKmsForceDestroy,
		Groups:                       tfvars.Groups,
		InitialGroupConfig:           tfvars.InitialGroupConfig,
		FolderDeletionProtection:     tfvars.FolderDeletionProtection,
		ProjectDeletionPolicy:        tfvars.ProjectDeletionPolicy,
		WorkflowDeletionProtection:   tfvars.WorkflowDeletionProtection,
	}

	err := utils.WriteTfvars(filepath.Join(c.GenaiPath, BootstrapStep, "terraform.tfvars"), bootstrapTfvars)
	if err != nil {
		return err
	}

	// delete README-Jenkins.md due to private key checker false positive
	jenkinsReadme := filepath.Join(c.GenaiPath, BootstrapStep, "README-Jenkins.md")
	exist, err := utils.FileExists(jenkinsReadme)
	if err != nil {
		return err
	}
	if exist {
		err = os.Remove(jenkinsReadme)
		if err != nil {
			return err
		}
	}

	terraformDir := filepath.Join(c.GenaiPath, BootstrapStep)
	options := &terraform.Options{
		TerraformDir: terraformDir,
		Logger:       c.Logger,
		NoColor:      true,
	}
	// terraform deploy
	err = applyLocal(t, options, "", c.PolicyPath, c.ValidatorProject)
	if err != nil {
		return err
	}

	// read bootstrap outputs
	defaultRegion := terraform.OutputMap(t, options, "common_config")["default_region"]
	cbProjectID := terraform.Output(t, options, "cloudbuild_project_id")
	backendBucket := terraform.Output(t, options, "gcs_bucket_tfstate")
	backendBucketProjects := terraform.Output(t, options, "projects_gcs_bucket_tfstate")

	// replace backend and terraform init migrate
	err = s.RunStep("gcp-bootstrap.migrate-state", func() error {
		options.MigrateState = true
		err = utils.CopyFile(filepath.Join(options.TerraformDir, "backend.tf.example"), filepath.Join(options.TerraformDir, "backend.tf"))
		if err != nil {
			return err
		}
		err = utils.ReplaceStringInFile(filepath.Join(options.TerraformDir, "backend.tf"), "UPDATE_ME", backendBucket)
		if err != nil {
			return err
		}
		_, err := terraform.InitE(t, options)
		return err
	})
	if err != nil {
		return err
	}

	// replace all backend files
	err = s.RunStep("gcp-bootstrap.replace-backend-files", func() error {
		files, err := utils.FindFiles(c.GenaiPath, "backend.tf")
		if err != nil {
			return err
		}
		for _, file := range files {
			err = utils.ReplaceStringInFile(file, "UPDATE_ME", backendBucket)
			if err != nil {
				return err
			}
			err = utils.ReplaceStringInFile(file, "UPDATE_PROJECTS_BACKEND", backendBucketProjects)
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return err
	}

	msg.PrintBuildMsg(cbProjectID, defaultRegion, c.DisablePrompt)

	// Check if image build was successful.
	err = gcp.NewGCP().WaitBuildSuccess(t, cbProjectID, defaultRegion, "tf-cloudbuilder", "", "Terraform Image builder Build Failed for tf-cloudbuilder repository.", MaxBuildRetries, MaxErrorRetries, TimeBetweenErrorRetries)
	if err != nil {
		return err
	}

	//prepare policies repo
	gcpPoliciesPath := filepath.Join(c.CheckoutPath, PoliciesRepo)
	policiesConf := utils.CloneCSR(t, PoliciesRepo, gcpPoliciesPath, cbProjectID, c.Logger)
	policiesBranch := "main"

	err = s.RunStep("gcp-bootstrap.gcp-policies", func() error {
		return preparePoliciesRepo(policiesConf, policiesBranch, c.GenaiPath, gcpPoliciesPath)
	})
	if err != nil {
		return err
	}

	//prepare bootstrap repo
	gcpBootstrapPath := filepath.Join(c.CheckoutPath, BootstrapRepo)
	bootstrapConf := utils.CloneCSR(t, BootstrapRepo, gcpBootstrapPath, cbProjectID, c.Logger)
	stageConf := StageConf{
		Stage:               BootstrapRepo,
		CICDProject:         cbProjectID,
		DefaultRegion:       defaultRegion,
		Step:                BootstrapStep,
		Repo:                BootstrapRepo,
		CustomTargetDirPath: "envs/shared",
		GitConf:             bootstrapConf,
		Envs:                []string{"shared"},
	}

	// if groups creation is enable the helper will just push the code
	// because Cloud Build build will fail until bootstrap
	// service account is granted Group Admin role in the
	// Google Workspace by a Super Admin.
	// https://github.com/terraform-google-modules/terraform-google-group/blob/main/README.md#google-workspace-formerly-known-as-g-suite-roles
	if tfvars.HasGroupsCreation() {
		err = saveBootstrapCodeOnly(t, stageConf, s, c)
	} else {
		err = deployStage(t, stageConf, s, c)
	}

	if err != nil {
		return err
	}
	// Init gcp-bootstrap terraform
	err = s.RunStep("gcp-bootstrap.init-tf", func() error {
		options := &terraform.Options{
			TerraformDir: filepath.Join(gcpBootstrapPath, "envs", "shared"),
			Logger:       c.Logger,
			NoColor:      true,
		}
		_, err := terraform.InitE(t, options)
		return err
	})
	if err != nil {
		return err
	}
	fmt.Println("end of bootstrap deploy")

	return nil
}

func DeployOrgStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, outputs BootstrapOutputs, c CommonConf) error {

	createACMAPolicy := testutils.GetOrgACMPolicyID(t, tfvars.OrgID) == ""

	orgTfvars := OrgTfvars{
		DomainsToAllow:                        tfvars.DomainsToAllow,
		EssentialContactsDomains:              tfvars.EssentialContactsDomains,
		SccNotificationName:                   tfvars.SccNotificationName,
		RemoteStateBucket:                     outputs.RemoteStateBucket,
		CreateACMAPolicy:                      createACMAPolicy,
		CreateUniqueTagKey:                    tfvars.CreateUniqueTagKey,
		AuditLogsTableDeleteContentsOnDestroy: tfvars.AuditLogsTableDeleteContentsOnDestroy,
		EnableSccResourcesInTerraform:         tfvars.EnableSccResourcesInTerraform,
		LogExportStorageForceDestroy:          tfvars.LogExportStorageForceDestroy,
		LogExportStorageLocation:              tfvars.LogExportStorageLocation,
		BillingExportDatasetLocation:          tfvars.BillingExportDatasetLocation,
		BillingDataUsers:                      tfvars.BillingDataUsers,
		AuditDataUsers:                        tfvars.AuditDataUsers,
		KmsPreventDestroy:                     tfvars.KmsPreventDestroy,
		CaiMonitoringKmsForceDestroy:          tfvars.CaiMonitoringKmsForceDestroy,
	}
	if tfvars.HasGroupsCreation() {
		orgTfvars.GcpGroups = GcpGroups{}
		if (*tfvars.Groups.OptionalGroups.GcpSecurityReviewer) != "" {
			orgTfvars.GcpGroups.SecurityReviewer = tfvars.Groups.OptionalGroups.GcpSecurityReviewer
		}
		if (*tfvars.Groups.OptionalGroups.GcpNetworkViewer) != "" {
			orgTfvars.GcpGroups.NetworkViewer = tfvars.Groups.OptionalGroups.GcpNetworkViewer
		}
		if (*tfvars.Groups.OptionalGroups.GcpSccAdmin) != "" {
			orgTfvars.GcpGroups.SccAdmin = tfvars.Groups.OptionalGroups.GcpSccAdmin
		}
		if (*tfvars.Groups.OptionalGroups.GcpGlobalSecretsAdmin) != "" {
			orgTfvars.GcpGroups.GlobalSecretsAdmin = tfvars.Groups.OptionalGroups.GcpGlobalSecretsAdmin
		}
	}

	err := utils.WriteTfvars(filepath.Join(c.GenaiPath, OrgStep, "envs", "shared", "terraform.tfvars"), orgTfvars)
	if err != nil {
		return err
	}

	conf := utils.CloneCSR(t, OrgRepo, filepath.Join(c.CheckoutPath, OrgRepo), outputs.CICDProject, c.Logger)
	stageConf := StageConf{
		Stage:         OrgRepo,
		CICDProject:   outputs.CICDProject,
		DefaultRegion: outputs.DefaultRegion,
		Step:          OrgStep,
		Repo:          OrgRepo,
		GitConf:       conf,
		Envs:          []string{"shared"},
	}

	return deployStage(t, stageConf, s, c)
}

func DeployEnvStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, outputs BootstrapOutputs, c CommonConf) error {

	envsTfvars := EnvsTfvars{
		MonitoringWorkspaceUsers: tfvars.MonitoringWorkspaceUsers,
		RemoteStateBucket:        outputs.RemoteStateBucket,
		KmsPreventDestroy:        tfvars.KmsPreventDestroy,
	}
	if tfvars.HasGroupsCreation() {
		envsTfvars.MonitoringWorkspaceUsers = (*tfvars.Groups).RequiredGroups.MonitoringWorkspaceUsers
	}
	err := utils.WriteTfvars(filepath.Join(c.GenaiPath, EnvironmentsStep, "terraform.tfvars"), envsTfvars)
	if err != nil {
		return err
	}

	conf := utils.CloneCSR(t, EnvironmentsRepo, filepath.Join(c.CheckoutPath, EnvironmentsRepo), outputs.CICDProject, c.Logger)
	stageConf := StageConf{
		Stage:         EnvironmentsRepo,
		CICDProject:   outputs.CICDProject,
		DefaultRegion: outputs.DefaultRegion,
		Step:          EnvironmentsStep,
		Repo:          EnvironmentsRepo,
		GitConf:       conf,
		Envs:          []string{"production", "nonproduction", "development"},
	}

	return deployStage(t, stageConf, s, c)
}

func DeployNetworksStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, outputs BootstrapOutputs, c CommonConf) error {

	localStep := []string{"shared"}

	// shared
	sharedTfvars := NetSharedTfvars{
		TargetNameServerAddresses: tfvars.TargetNameServerAddresses,
	}
	err := utils.WriteTfvars(filepath.Join(c.GenaiPath, DualSvpcStep, "shared.auto.tfvars"), sharedTfvars)
	if err != nil {
		return err
	}
	// production
	productionTfvars := NetProductionTfvars{
		TargetNameServerAddresses: tfvars.TargetNameServerAddresses,
	}
	err = utils.WriteTfvars(filepath.Join(c.GenaiPath, DualSvpcStep, "production.auto.tfvars"), productionTfvars)
	if err != nil {
		return err
	}
	// common
	commonTfvars := NetCommonTfvars{
		Domain:                     tfvars.Domain,
		PerimeterAdditionalMembers: tfvars.PerimeterAdditionalMembers,
		RemoteStateBucket:          outputs.RemoteStateBucket,
	}
	err = utils.WriteTfvars(filepath.Join(c.GenaiPath, DualSvpcStep, "common.auto.tfvars"), commonTfvars)
	if err != nil {
		return err
	}
	//access_context
	accessContextTfvars := NetAccessContextTfvars{
		AccessContextManagerPolicyID: testutils.GetOrgACMPolicyID(t, tfvars.OrgID),
	}
	err = utils.WriteTfvars(filepath.Join(c.GenaiPath, DualSvpcStep, "access_context.auto.tfvars"), accessContextTfvars)
	if err != nil {
		return err
	}

	conf := utils.CloneCSR(t, NetworksRepo, filepath.Join(c.CheckoutPath, NetworksRepo), outputs.CICDProject, c.Logger)
	stageConf := StageConf{
		Stage:         NetworksRepo,
		StageSA:       outputs.NetworkSA,
		CICDProject:   outputs.CICDProject,
		DefaultRegion: outputs.DefaultRegion,
		Step:          DualSvpcStep,
		Repo:          NetworksRepo,
		GitConf:       conf,
		HasLocalStep:  true,
		LocalSteps:    localStep,
		GroupingUnits: []string{"envs"},
		Envs:          []string{"production", "nonproduction", "development"},
	}
	return deployStage(t, stageConf, s, c)
}

func DeployProjectsStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, outputs BootstrapOutputs, c CommonConf) error {

	// shared
	sharedTfvars := ProjSharedTfvars{
		DefaultRegion:      tfvars.DefaultRegion,
		ServiceCatalogRepo: tfvars.ServiceCatalogRepo,
		ArtifactsRepoName:  tfvars.ArtifactsRepoName,
		PreventDestroy:     tfvars.PreventDestroy,
	}
	err := utils.WriteTfvars(filepath.Join(c.GenaiPath, ProjectsStep, "shared.auto.tfvars"), sharedTfvars)
	if err != nil {
		return err
	}
	// common
	commonTfvars := ProjCommonTfvars{
		RemoteStateBucket: outputs.RemoteStateBucket,
	}
	err = utils.WriteTfvars(filepath.Join(c.GenaiPath, ProjectsStep, "common.auto.tfvars"), commonTfvars)
	if err != nil {
		return err
	}

	//for each environment
	for _, envfile := range []string{
		"development.auto.tfvars",
		"nonproduction.auto.tfvars",
		"production.auto.tfvars",
	} {
		envName := strings.TrimSuffix(envfile, ".auto.tfvars")

		envTfvars := ProjEnvTfvars{
			LocationKMS: tfvars.LocationKMS,
			LocationGCS: tfvars.LocationGCS,
			Env:         envName,
		}

		err = utils.WriteTfvars(filepath.Join(c.GenaiPath, ProjectsStep, envfile), envTfvars)
		if err != nil {
			return err
		}
	}

	conf := utils.CloneCSR(t, ProjectsRepo, filepath.Join(c.CheckoutPath, ProjectsRepo), outputs.CICDProject, c.Logger)
	stageConf := StageConf{
		Stage:         ProjectsRepo,
		StageSA:       outputs.ProjectsSA,
		CICDProject:   outputs.CICDProject,
		DefaultRegion: outputs.DefaultRegion,
		Step:          ProjectsStep,
		Repo:          ProjectsRepo,
		GitConf:       conf,
		HasLocalStep:  true,
		LocalSteps:    []string{"shared"},
		GroupingUnits: []string{"ml_business_unit"},
		Envs:          []string{"production", "nonproduction", "development"},
	}

	return deployStage(t, stageConf, s, c)

}

func DeployExampleAppStage(t testing.TB, s steps.Steps, tfvars GlobalTFVars, io InfraPipelineOutputs, c CommonConf) error {
	//prepare policies repo
	gcpPoliciesPath := filepath.Join(c.CheckoutPath, "gcp-policies-app-infra")
	policiesConf := utils.CloneCSR(t, PoliciesRepo, gcpPoliciesPath, io.InfraPipeProj, c.Logger)
	if err := s.RunStep("ml_business_unit.gcp-policies-app-infra", func() error {
		return preparePoliciesRepo(policiesConf, "main", c.GenaiPath, gcpPoliciesPath)
	}); err != nil {
		return err
	}

	var repos []string
	for repo := range io.Repos {
		repos = append(repos, repo)
	}
	sort.Strings(repos)

	for _, repo := range repos {
		perRepo := io.Repos[repo]
		project := strings.TrimPrefix(repo, "ml-")
		// create tfvars files
		tfvarsPath := filepath.Join(c.GenaiPath, AppInfraStep, "projects", project, "terraform.tfvars")
		if project == "service-catalog" {
			tf := ServiceCatalogTfvars{
				InstanceRegion:     tfvars.InstanceRegion,
				RemoteStateBucket:  io.RemoteStateBucket,
				LogBucket:          io.LogBucket,
				BucketForceDestroy: tfvars.BucketForceDestroy,
			}
			if err := utils.WriteTfvars(tfvarsPath, tf); err != nil {
				return err
			}
		} else {
			tf := AppInfraCommonTfvars{
				InstanceRegion:     tfvars.InstanceRegion,
				RemoteStateBucket:  io.RemoteStateBucket,
				BucketForceDestroy: tfvars.BucketForceDestroy,
			}
			if err := utils.WriteTfvars(tfvarsPath, tf); err != nil {
				return err
			}
		}
		// update backend bucket
		if err := utils.ReplaceStringInFile(filepath.Join(c.GenaiPath, AppInfraStep, "projects", project, "ml_business_unit", "shared", "backend.tf"), "UPDATE_APP_INFRA_BUCKET", perRepo.StateBucket); err != nil {
			return err
		}

		checkoutDir := filepath.Join(c.CheckoutPath, repo)
		conf := utils.CloneCSR(t, repo, checkoutDir, io.InfraPipeProj, c.Logger)

		stageConf := StageConf{
			Stage:         repo,
			CICDProject:   io.InfraPipeProj,
			DefaultRegion: io.DefaultRegion,
			Step:          filepath.Join(AppInfraStep, "projects", project),
			Repo:          repo,
			GitConf:       conf,
			Envs:          []string{"shared"},
			StageSA:       perRepo.TerraformSA,
		}
		if err := deployStage(t, stageConf, s, c); err != nil {
			return err
		}

		switch project {
		//configuring service catalog solutions cloud source repository
		case "service-catalog":
			if strings.TrimSpace(io.ServiceCatalogProjID) == "" {
				break
			}
			repoPath := filepath.Join(c.CheckoutPath, ServiceCatalogRepo)
			sourcePath := filepath.Join(c.GenaiPath, AppInfraStep, "source_repos", "service-catalog")

			gitConf := utils.CloneCSR(t, ServiceCatalogRepo, repoPath, io.ServiceCatalogProjID, c.Logger)

			if err := s.RunStep("service-catalog.checkout-main", func() error {
				return gitConf.CheckoutBranch("main")
			}); err != nil {
				return err
			}

			if err := s.RunStep("service-catalog.copy-template", func() error {
				return utils.CopyDirectory(sourcePath, repoPath)
			}); err != nil {
				return err
			}

			if err := s.RunStep("service-catalog.commit-img", func() error {
				imgDst := filepath.Join(repoPath, "img")
				if ok, _ := utils.FileExists(imgDst); !ok {
					return nil
				}
				return gitConf.CommitPaths("Add img directory", "img")
			}); err != nil {
				return err
			}
			//This module need to be in an isolated commit
			if err := s.RunStep("service-catalog.commit-modules", func() error {
				modDst := filepath.Join(repoPath, "modules")
				if ok, _ := utils.FileExists(modDst); !ok {
					return nil
				}
				return gitConf.CommitPaths("Initialize Service Catalog Build Repo", "modules")
			}); err != nil {
				return err
			}

			if err := s.RunStep("service-catalog.push", func() error {
				return gitConf.PushBranch("main", "origin")
			}); err != nil {
				return err
			}
			if err := s.RunStep("service-catalog.wait-build", func() error {
				sha, err := gitConf.GetCommitSha()
				if err != nil {
					return err
				}
				return gcp.NewGCP().WaitBuildSuccess(t, io.ServiceCatalogProjID, io.DefaultRegion, io.ServiceCatalogProjID, sha, "Service Catalog build failed.", MaxBuildRetries, MaxErrorRetries, TimeBetweenErrorRetries)
			}); err != nil {
				return err
			}

		//configuring artifact application cloud source repository
		case "artifact-publish":
			if strings.TrimSpace(io.ArtifactPublishProjID) == "" {
				break
			}

			repoPath := filepath.Join(c.CheckoutPath, ArtifactPublishRepo)
			sourcePath := filepath.Join(c.GenaiPath, AppInfraStep, "source_repos", "artifact-publish")

			if err := s.RunStep("publish-artifacts.clone", func() error {
				utils.CloneCSR(t, ArtifactPublishRepo, repoPath, io.ArtifactPublishProjID, c.Logger)
				return nil
			}); err != nil {
				return err
			}

			gitConf := utils.CloneCSR(t, ArtifactPublishRepo, repoPath, io.ArtifactPublishProjID, c.Logger)
			if err := s.RunStep("publish-artifacts.checkout-main", func() error {
				return gitConf.CheckoutBranch("main")
			}); err != nil {
				return err
			}

			if err := s.RunStep("publish-artifacts.empty-commit", func() error {
				return gitConf.CommitAllowEmpty("Initialize Repository")
			}); err != nil {
				return err
			}

			if err := s.RunStep("publish-artifacts.copy-template", func() error {
				return utils.CopyDirectory(sourcePath, repoPath)
			}); err != nil {
				return err
			}

			if err := s.RunStep("publish-artifacts.commit-files", func() error {
				return gitConf.CommitFiles("Build Images")
			}); err != nil {
				return err
			}

			if err := s.RunStep("publish-artifacts.push", func() error {
				return gitConf.PushBranch("main", "origin")
			}); err != nil {
				return err
			}
			if err := s.RunStep("publish-artifacts.wait-build", func() error {
				sha, err := gitConf.GetCommitSha()
				if err != nil {
					return err
				}
				return gcp.NewGCP().WaitBuildSuccess(t, io.ArtifactPublishProjID, io.DefaultRegion, ArtifactPublishRepo, sha, "Publish Artifacts build failed.", MaxBuildRetries, MaxErrorRetries, TimeBetweenErrorRetries)
			}); err != nil {
				return err
			}
		}
	}
	return nil
}

func deployStage(t testing.TB, sc StageConf, s steps.Steps, c CommonConf) error {

	err := sc.GitConf.CheckoutBranch("plan")
	if err != nil {
		return err
	}

	err = s.RunStep(fmt.Sprintf("%s.copy-code", sc.Stage), func() error {
		return copyStepCode(t, sc.GitConf, c.GenaiPath, c.CheckoutPath, sc.Repo, sc.Step, sc.CustomTargetDirPath)
	})
	if err != nil {
		return err
	}

	groupunit := []string{}
	if sc.HasLocalStep {
		groupunit = sc.GroupingUnits
	}

	for _, bu := range groupunit {
		for _, localStep := range sc.LocalSteps {
			buOptions := &terraform.Options{
				TerraformDir: filepath.Join(filepath.Join(c.CheckoutPath, sc.Repo), bu, localStep),
				Logger:       c.Logger,
				NoColor:      true,
			}

			err := s.RunStep(fmt.Sprintf("%s.%s.apply-%s", sc.Stage, bu, localStep), func() error {
				return applyLocal(t, buOptions, sc.StageSA, c.PolicyPath, c.ValidatorProject)
			})
			if err != nil {
				return err
			}
		}
	}

	err = s.RunStep(fmt.Sprintf("%s.plan", sc.Stage), func() error {
		return planStage(t, sc.GitConf, sc.CICDProject, sc.DefaultRegion, sc.Repo)
	})
	if err != nil {
		return err
	}

	for _, env := range sc.Envs {
		err = s.RunStep(fmt.Sprintf("%s.%s", sc.Stage, env), func() error {
			aEnv := env
			if env == "shared" {
				aEnv = "production"
			}
			return applyEnv(t, sc.GitConf, sc.CICDProject, sc.DefaultRegion, sc.Repo, aEnv)
		})
		if err != nil {
			return err
		}
	}

	fmt.Println("end of", sc.Step, "deploy")
	return nil
}

func preparePoliciesRepo(policiesConf utils.GitRepo, policiesBranch, genaiPath, gcpPoliciesPath string) error {
	err := policiesConf.CheckoutBranch(policiesBranch)
	if err != nil {
		return err
	}
	err = utils.CopyDirectory(filepath.Join(genaiPath, "policy-library"), gcpPoliciesPath)
	if err != nil {
		return err
	}
	err = policiesConf.CommitFiles("Initialize policy library repo")
	if err != nil {
		return err
	}
	return policiesConf.PushBranch(policiesBranch, "origin")
}

func copyStepCode(t testing.TB, conf utils.GitRepo, genaiPath, checkoutPath, repo, step, customPath string) error {
	gcpPath := filepath.Join(checkoutPath, repo)
	targetDir := gcpPath
	if customPath != "" {
		targetDir = filepath.Join(gcpPath, customPath)
	}
	err := utils.CopyDirectory(filepath.Join(genaiPath, step), targetDir)
	if err != nil {
		return err
	}
	err = utils.CopyFile(filepath.Join(genaiPath, "build/cloudbuild-tf-apply.yaml"), filepath.Join(gcpPath, "cloudbuild-tf-apply.yaml"))
	if err != nil {
		return err
	}
	err = utils.CopyFile(filepath.Join(genaiPath, "build/cloudbuild-tf-plan.yaml"), filepath.Join(gcpPath, "cloudbuild-tf-plan.yaml"))
	if err != nil {
		return err
	}
	return utils.CopyFile(filepath.Join(genaiPath, "build/tf-wrapper.sh"), filepath.Join(gcpPath, "tf-wrapper.sh"))
}

func planStage(t testing.TB, conf utils.GitRepo, project, region, repo string) error {

	err := conf.CommitFiles(fmt.Sprintf("Initialize %s repo", repo))
	if err != nil {
		return err
	}
	err = conf.PushBranch("plan", "origin")
	if err != nil {
		return err
	}

	commitSha, err := conf.GetCommitSha()
	if err != nil {
		return err
	}

	return gcp.NewGCP().WaitBuildSuccess(t, project, region, repo, commitSha, fmt.Sprintf("Terraform %s plan build Failed.", repo), MaxBuildRetries, MaxErrorRetries, TimeBetweenErrorRetries)
}

func saveBootstrapCodeOnly(t testing.TB, sc StageConf, s steps.Steps, c CommonConf) error {

	err := sc.GitConf.CheckoutBranch("plan")
	if err != nil {
		return err
	}

	err = s.RunStep(fmt.Sprintf("%s.copy-code", sc.Stage), func() error {
		return copyStepCode(t, sc.GitConf, c.GenaiPath, c.CheckoutPath, sc.Repo, sc.Step, sc.CustomTargetDirPath)
	})
	if err != nil {
		return err
	}

	err = s.RunStep(fmt.Sprintf("%s.plan", sc.Stage), func() error {
		err := sc.GitConf.CommitFiles(fmt.Sprintf("Initialize %s repo", sc.Repo))
		if err != nil {
			return err
		}
		return sc.GitConf.PushBranch("plan", "origin")
	})

	if err != nil {
		return err
	}

	for _, env := range sc.Envs {
		err = s.RunStep(fmt.Sprintf("%s.%s", sc.Stage, env), func() error {
			aEnv := env
			if env == "shared" {
				aEnv = "production"
			}
			err := sc.GitConf.CheckoutBranch(aEnv)
			if err != nil {
				return err
			}
			return sc.GitConf.PushBranch(aEnv, "origin")
		})
		if err != nil {
			return err
		}
	}

	fmt.Println("end of", sc.Step, "deploy")
	return nil
}

func applyEnv(t testing.TB, conf utils.GitRepo, project, region, repo, environment string) error {
	err := conf.CheckoutBranch(environment)
	if err != nil {
		return err
	}
	err = conf.PushBranch(environment, "origin")
	if err != nil {
		return err
	}
	commitSha, err := conf.GetCommitSha()
	if err != nil {
		return err
	}

	return gcp.NewGCP().WaitBuildSuccess(t, project, region, repo, commitSha, fmt.Sprintf("Terraform %s apply %s build Failed.", repo, environment), MaxBuildRetries, MaxErrorRetries, TimeBetweenErrorRetries)
}

func applyLocal(t testing.TB, options *terraform.Options, serviceAccount, policyPath, ValidatorProjectID string) error {
	var err error

	if serviceAccount != "" {
		err = os.Setenv("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT", serviceAccount)
		if err != nil {
			return err
		}
	}

	_, err = terraform.InitE(t, options)
	if err != nil {
		return err
	}
	_, err = terraform.PlanE(t, options)
	if err != nil {
		return err
	}

	// Runs gcloud terraform vet
	if ValidatorProjectID != "" {
		err = TerraformVet(t, options.TerraformDir, policyPath, ValidatorProjectID)
		if err != nil {
			return err
		}
	}

	_, err = terraform.ApplyE(t, options)
	if err != nil {
		return err
	}

	if serviceAccount != "" {
		err = os.Unsetenv("GOOGLE_IMPERSONATE_SERVICE_ACCOUNT")
		if err != nil {
			return err
		}
	}
	return nil
}
