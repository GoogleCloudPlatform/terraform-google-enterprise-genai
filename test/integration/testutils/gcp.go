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

package testutils

import (
	"fmt"
	"strings"

	"github.com/mitchellh/go-testing-interface"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
)

// CleanOrgACMPolicyID deletes orphan scoped policies if approaching org quota limit (>= 40)
func CleanOrgACMPolicyID(t testing.TB, orgID, currentFolder, terraformSA string) {
	policies := gcloud.Runf(t, "access-context-manager policies list --organization %s --filter=scopes:folders/* --impersonate-service-account %s --quiet", orgID, terraformSA).Array()
	if len(policies) < 40 {
		return
	}
	for _, p := range policies {
		fID := strings.TrimPrefix(p.Get("scopes.0").String(), "folders/")
		if fID != currentFolder && fID != "" {
			_, err := gcloud.RunCmdE(t, fmt.Sprintf("resource-manager folders describe %s --impersonate-service-account %s", fID, terraformSA))
			if err != nil && (strings.Contains(err.Error(), "NOT_FOUND") || strings.Contains(err.Error(), "404") || strings.Contains(err.Error(), "not found")) {
				gcloud.RunCmdE(t, fmt.Sprintf("access-context-manager policies delete %s --impersonate-service-account %s --quiet", p.Get("name").String(), terraformSA))
			}
		}
	}
}

// GetOrgACMPolicyID gets the Organization Access Context Manager Policy ID
func GetOrgACMPolicyID(t testing.TB, orgID, folderID string) string {
	policies := gcloud.Runf(t, "access-context-manager policies list --organization %s --filter parent:organizations/%s --quiet", orgID, orgID).Array()
	for _, p := range policies {
		if scope := p.Get("scopes.0").String(); scope == "" || scope == "folders/"+folderID {
			return GetLastSplitElement(p.Get("name").String(), "/")
		}
	}
	return ""
}
