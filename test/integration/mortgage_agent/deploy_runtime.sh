#!/usr/bin/env bash
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Build real MCP images, point Cloud Run at them, and deploy the ADK agent
# to Agent Engine so verify can chat the Playground prompts.

set -eu

PROJECT_ID="${PROJECT_ID:?}"
PROJECT_NUMBER="${PROJECT_NUMBER:?}"
ORG_ID="${ORG_ID:?}"
REGION="${REGION:?}"
EXAMPLE_DIR="${EXAMPLE_DIR:?}"
ARTIFACT_REGISTRY_URL="${ARTIFACT_REGISTRY_URL:?}"
AGENT_GATEWAY_ID="${AGENT_GATEWAY_ID:?}"
MCP_INVOKER_SA="${MCP_INVOKER_SA:?}"
STAGING_BUCKET="${STAGING_BUCKET:?}"
AGENT_ENGINE_OUT="${AGENT_ENGINE_OUT:?}"

export PROJECT_ID PROJECT_NUMBER ORG_ID REGION
export MCP_INVOKER_SA_EMAIL="${MCP_INVOKER_SA}"

gcs_staging="${STAGING_BUCKET#gs://}"
gcloud storage buckets describe "gs://${gcs_staging}" --project="${PROJECT_ID}" >/dev/null

build_and_rollout() {
  local service="$1"
  local src="$2"
  local image="${ARTIFACT_REGISTRY_URL}/${service}:cft"

  echo "Building ${service} from ${src}"
  gcloud builds submit "${src}" \
    --project="${PROJECT_ID}" \
    --gcs-source-staging-dir="gs://${gcs_staging}/mcp-src/${service}" \
    --gcs-log-dir="gs://${gcs_staging}/mcp-logs/${service}" \
    --tag="${image}" \
    --quiet

  echo "Updating Cloud Run ${service}"
  gcloud run services update "${service}" \
    --project="${PROJECT_ID}" \
    --region="${REGION}" \
    --image="${image}" \
    --ingress=internal-and-cloud-load-balancing \
    --quiet
}

build_and_rollout legacy-dms "${EXAMPLE_DIR}/src/legacy-dms"
build_and_rollout corporate-email "${EXAMPLE_DIR}/src/corporate-email"
build_and_rollout income-verification "${EXAMPLE_DIR}/src/income-verification-api"

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

agent_dir="${EXAMPLE_DIR}/src/mortgage_agent"
cd "${agent_dir}"
uv python install 3.12
uv sync --frozen

deploy_log="$(mktemp)"
set +e
uv run python deploy_agent.py \
  --project="${PROJECT_ID}" \
  --region="${REGION}" \
  --staging-bucket="gs://${gcs_staging}" \
  --enable-agent-identity \
  --agent-name=mortgage-agent \
  --display-name="CFT Mortgage Assistant" \
  --agent-gateway="${AGENT_GATEWAY_ID}" \
  --mcp-invoker-sa="${MCP_INVOKER_SA}" \
  --model-endpoint-location=global >"${deploy_log}" 2>&1
deploy_status=$?
set -e
cat "${deploy_log}"
if [ "${deploy_status}" -ne 0 ]; then
  echo "deploy_agent.py failed" >&2
  exit "${deploy_status}"
fi

engine="$(grep -Eo 'projects/[^[:space:]]+/locations/[^[:space:]]+/reasoningEngines/[0-9]+' "${deploy_log}" | tail -n1 || true)"
if [[ -z "${engine}" ]]; then
  echo "Could not parse reasoning engine name from deploy_agent.py output" >&2
  exit 1
fi

printf '%s\n' "${engine}" > "${AGENT_ENGINE_OUT}"
echo "Wrote ${engine} to ${AGENT_ENGINE_OUT}"
