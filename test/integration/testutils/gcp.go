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
	"github.com/mitchellh/go-testing-interface"

	"github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test/pkg/gcloud"
)

// GetOrgACMPolicyID gets the Organization Access Context Manager Policy ID
func GetOrgACMPolicyID(t testing.TB, orgID string) string {
	policies := gcloud.Runf(t, "access-context-manager policies list --organization %s --filter parent:organizations/%s --quiet", orgID, orgID).Array()
	for _, p := range policies {
		if len(p.Get("scopes").Array()) == 0 {
			return GetLastSplitElement(p.Get("name").String(), "/")
		}
	}
	if len(policies) > 0 {
		return GetLastSplitElement(policies[0].Get("name").String(), "/")
	}
	return ""
}
