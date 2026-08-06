# Mortgage Agent on Gemini Enterprise Agent Platform

## Overview

Gemini Enterprise Agent Platform is an open platform for building, scaling, governing, and optimizing enterprise-grade AI agents grounded in your data.

Agent Runtime provides the managed execution environment for running agents, such as those built with the open-source [Agent Development Kit (ADK)](https://google.github.io/adk-docs/) securely within Google Cloud.

**Agent Gateway** is the networking component of the platform's Agent Governance suite. It acts as the network entry and exit point for all agent interactions, allowing security administrators to enforce centralized governance without requiring developers to manage complex networking primitives. This example uses the **Agent-to-Anywhere (egress)** mode.

To enforce security policies, Agent Gateway integrates tightly with the rest of the ecosystem:

- **Agent Registry:** A central library of approved agents and tools, including third-party MCP servers.
- **Agent Identity:** A unique, trackable persona for every agent, secured automatically with end-to-end mTLS.
- **[Identity-Aware Proxy (IAP)](https://cloud.google.com/iap/docs/concepts-overview) & IAM:** The default enforcement layer that validates the agent's identity against fine-grained IAM permissions before allowing calls to specific tools.
- **[Model Armor](https://cloud.google.com/security-command-center/docs/model-armor-overview):** An AI security guardrail integrated via Service Extensions to sanitize content and protect against prompt injection attacks or data leakage.
- **Agent Observability:** An Agent Gateway dashboard in the Cloud Console, backed by Log Analytics, that surfaces scorecards, charts, and egress traffic logs so you can trace and audit every governed agent interaction.

The MCP servers in this example are restricted and exposed through an Internal Application Load Balancer with a [Serverless NEG](https://cloud.google.com/load-balancing/docs/negs/serverless-neg-concepts).
**IMPORTANT**: This requires you to own a public DNS domain in order to provision a Google-managed certificate for the Internal Application Load Balancer.

For more information about the technologies used in this example, please refer to the following resources:

- [Gemini Enterprise Agent Platform](https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform)
- [Agent Development Kit (ADK) Documentation](https://google.github.io/adk-docs/)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Model Armor Overview](https://cloud.google.com/security-command-center/docs/model-armor-overview)
- [Private Service Connect Overview](https://cloud.google.com/vpc/docs/private-service-connect)

This example is an adapted version of the Agent Gateway Demo from the Google Cloud codebase. You can find the original example in the [Cloud Networking Solutions](https://github.com/GoogleCloudPlatform/cloud-networking-solutions) repository.

## Steps Involved

After ensuring all requirements are satisfied, you will complete the following steps:

1. Provision the core infrastructure stack using Terraform.
1. Build and deploy internal tools as MCP servers on Cloud Run.
1. Deploy an ADK agent to Agent Runtime using PSC Interface egress.
1. Configure Agent Gateway service extensions for identity-based access (IAM) and content screening (Model Armor).
1. Trace and validate the secure end-to-end execution of the agent.

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) v1.12 or later
- [Authenticated Google Cloud SDK](https://cloud.google.com/sdk/docs/authorizing)
- [Docker](https://docs.docker.com/engine/install/ubuntu/) to build and push the MCP server container images
- [Python](https://www.python.org/downloads/) 3.12 or later to develop and package the ADK agent
- [uv](docs.astral.sh)for Python dependency management

## Prerequisites

1. Ensure you have a Google Cloud project created with billing enabled, then authenticated using the following command:

   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project <your-project-id>
   ```

1. Ensure your project has the required APIs enabled. You can enable them using the following command:

   ```bash
   gcloud services enable \
      compute.googleapis.com \
      serviceusage.googleapis.com \
      cloudresourcemanager.googleapis.com \
      iam.googleapis.com \
      storage.googleapis.com \
      dns.googleapis.com
   ```

1. Install the necessary toolchain. On Cloud Shell, most of these are already present. On a local workstation, run:

   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
   sudo install skaffold /usr/local/bin/
   sudo apt-get install -y gettext-base
   ```

**IMPORTANT**:
1. A public DNS domain **must exist** to run the test.
1. Ensure that the KMS organization policy constraint is disabled.

### Domain Registration (Optional)

If you do not currently own a public DNS domain, you can register one directly within your Google Cloud project using ***Cloud Domains***. Prices typically start at ***$12 per year***.

To register a domain via the Google Cloud Console:

1. Navigate to Network Services > Cloud Domains (or search for "Cloud Domains").
1. Click Register Domain.
1. Search for your desired domain name to check availability and pricing.
1. Select the domain you want to purchase and click Continue.
1. Fill in the required DNS configuration (you can choose to have Cloud DNS automatically set up a public zone for you).
1. Complete the checkout process.


#### Export the required environment variables:

   ```bash
   export PROJECT_ID=$(gcloud config get-value project)
   export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
   export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID | awk '$2 == "organization" {print $1}')
   export REGION="us-central1"
   export DOMAIN_NAME="mortgageexample.com"
   ```

1. Create the public Cloud DNS zone — Certificate Manager validates the regional managed certificate by writing CNAMEs into it:

   ```bash
   gcloud dns managed-zones create mortgage-example-com \
   --dns-name="${DOMAIN_NAME}." \
   --description="Public zone for ${DOMAIN_NAME}" \
   --visibility=public
   ```

> **Note:** If your domain is already registered through Google Cloud Domains (or if you have previously set it up), this public DNS zone might already exist in your project. You can check your existing zones by running `gcloud dns managed-zones list`. If the zone already exists, you can skip this step.

### Step 1: Infrastructure Deployment (Terraform)

1. Navigate to this directory:

   ```bash
   cd examples/mortgage_agent
   ```

1. Rename `terraform.example.tfvars` to `terraform.tfvars` and update the file with values from your environment:


   ```bash
   mv terraform.example.tfvars terraform.tfvars
   ```

1. Initialize and apply the Terraform configuration:

   ```bash
   terraform init
   terraform plan -input=false -out mortgage.tfplan
   terraform apply mortgage.tfplan
   ```

1. Retrieve and export the required outputs after a successful deployment:

   ```bash
   export PROJECT_ID=$(terraform output -raw project_id)
   export REGION=$(terraform output -raw region)
   export MCP_INGRESS=$(terraform output -raw mcp_cloud_run_ingress_annotation)
   export MCP_INVOKER_SA=$(terraform output -raw agent_mcp_invoker_email)
   export AGENT_GATEWAY_ID=$(terraform output -raw agent_gateway_id)
   ```

### Step 2: Build and deploy the MCP servers to Cloud Run

The three MCP servers are built from source, pushed to Artifact Registry, and deployed privately to Cloud Run using Skaffold. Skaffold natively resolves the environment variables in `skaffold.yaml` at runtime, then render with `envsubst`.

1. Substitute the template values:

   ```bash
   envsubst '${PROJECT_ID} ${REGION} ${MCP_INGRESS}' < skaffold.yaml.tmpl > skaffold.yaml
   for f in cloudrun/*.yaml.tmpl; do
     envsubst '${PROJECT_ID} ${REGION} ${MCP_INGRESS}' < "$f" > "${f%.tmpl}"
   done
   ```

1.Each Cloud Run service runs as a per-service runtime SA Terraform created `(e.g. mcp-legacy-dms@${PROJECT_ID}.iam.gserviceaccount.com)`. To deploy as those SAs you need `roles/iam.serviceAccountUser` on yourself:

   ```bash
   gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/iam.serviceAccountUser"
   ```

1. Build with Cloud Build and deploy with Skaffold. `MCP_INGRESS` comes from a Terraform output, so the rendered Cloud Run YAML stays in sync with Terraform state.:

   ```bash
   skaffold run
   ```

1. Verify:

   ```bash
   gcloud run services list --region=${REGION}
   ```

### Step 3: Deploy the mortgage agent to Agent Runtime

1. Grant all Agents the IAP Egressor role on all endpoints we have registered to the registry. The agent needs access to these endpoints because, when it's being deployed, it needs to reach github.com for packages and then reach the various Google APIs needed to deploy.

   ```bash
   ./scripts/grant_agent_mcp_egress.sh --bind-all-agents --endpoints
   ```

1. Deploy the agent with identity:

   ```bash
   cd src/mortgage_agent
   uv sync

   uv run python deploy_agent.py \
   --project=${PROJECT_ID} \
   --region=${REGION} \
   --enable-agent-identity \
   --agent-name=$(terraform output -raw agent_name) \
   --agent-gateway=$(terraform output -raw agent_gateway_id) \
   --mcp-invoker-sa=$(terraform output -raw agent_mcp_invoker_email) \
   --model-endpoint-location=global
   ```

When the script completes, copy the printed reasoningEngines/ into your shell (e.g. 4262292559201566720):

   ```bash
   export AGENT_ID=<NUMERIC_ID_FROM_OUTPUT>
   ```

### Step 4: Grant the agent per-MCP-server egress

The IAP REQUEST_AUTHZ extension authorizes each tool call by checking the agent's roles/iap.egressor on the specific MCP server or endpoint it's calling.

#### Use Case 1 - Unconditional grant scoped to specific MCP servers

   ```bash
   ./scripts/grant_agent_mcp_egress.sh \
      --mcp \
      --agent-id ${AGENT_ID} \
      --mcp-filter "legacy-dms income-verification"
   ```

#### Use Case 2 - Conditional grant (CEL) scoped to a specific MCP server

   ```bash
   ./scripts/grant_agent_mcp_egress.sh \
      --mcp \
      --agent-id ${AGENT_ID} \
      --mcp-filter "corporate-email" \
      --condition-expression              "api.getAttribute('iap.googleapis.com/mcp.tool.isReadOnly', false) == true || api.getAttribute('iap.googleapis.com/mcp.toolName','')==''" \
      --condition-title "ReadOnlyToolsOnly" \
      --condition-description "Restrict ${AGENT_ID} to read-only tools on corporate-email"
   ```

### Verify the bindings

Navigate to [Policies tab](https://console.cloud.google.com/agent-platform/policies/iam) and you'll see the list of Policies created against the Endpoints and Mcp Servers.
If there are no policies against any endpoints, run the script with the following config.

   ```bash
   ./scripts/grant_agent_mcp_egress.sh --agent-id $AGENT_ID --endpoints
   ```

## Test the agent in the Agent Platform console

The Agent Platform console ships with a Playground that lets you chat with the deployed agent directly. It's the fastest way to smoke-test tool calls and inspect traces before wiring the agent into Gemini Enterprise.

1. Open the [Agent Platform Deployments](https://console.cloud.google.com/agent-platform/runtimes) page in the Google Cloud console.
1. Use the Filter field if you need to narrow the runtime list, then click your `mortgage-agent` runtime.
1. Open the **Playground** tab.
1. Type a prompt to chat with the agent:

   ```text
   I am reviewing the Sterling familys current application. Can you summarize their 2024 and 2025 tax returns and verify if their total household income meets our 2026 debt-to-income requirements?
   ```

This should return a response from the Document Management tool and Income Verification tool, SSN's should also be redacted in this response. 5. Type a follow up prompt:

   ```text
   Can you send a summary of this to my email jane@example.com
   ```

1. The agent will be able to successfully send the email, as the conditional policy is not being enforced due to the IAP extension being in Dry Run mode.

Because the agent was deployed with OpenTelemetry instrumentation, the Playground exposes four side-panel views you can flip between as the agent responds:

1. Trace — full traces of the conversation, including the Agent Gateway, IAP REQUEST_AUTHZ, and Model Armor CONTENT_AUTHZ spans
1. Event — a graph of invoked tools and event details for the current turn
1. State — the agent's session state and tool inputs/outputs
1. Sessions — every session you've started against this runtime

## Enforce IAP Authorization

Update the IAP Enforcement mode to `null` to enforce the policies. Open the `terraform.tfvars` file, and update the mode from **DRY_RUN** to `null`:

   ```text
   # IAP Enforcement Mode ("DRY_RUN" or null)
   agent_gateway_iap_iam_enforcement_mode = null
   ```

1. Apply the change:

   ```bash
   terraform apply
   ```

1. Navigate back to the Playground and try the conversation again.

1. Type this prompt to chat with the agent.

   ```text
   I am reviewing the Sterling familys current application. Can you     summarize their 2024 and 2025 tax returns and verify if their total     household income meets our 2026 debt-to-income requirements?
   ```

This should return a response from the Document Management tool and Income Verification tool, SSN's should also be redacted in this response.

1. Type a follow up prompt:

   ```text
   Can you send a summary of this to my email jane@example.com
   ```

If everything has been setup correctly the agent should respond that it cannot send the email due to the authorization policy.

## Migrate Terraform State to Cloud Storage

1. Copy the backend and update `backend.tf` with the name of your Google Cloud Storage bucket for Terraform's state. Also update the `backend.tf` of all steps.

   ```bash
   export backend_bucket=$(terraform output -raw bucket_mortgage_terraform_state)
   echo "backend_bucket = ${backend_bucket}"

   cp backend.tf.example backend.tf

   for i in `find . -name 'backend.tf'`; do sed -i'' -e "s/UPDATE_ME/${backend_bucket}/" $i; done
   ```

1. Re-run `terraform init`. When you're prompted, agree to copy Terraform state to Cloud Storage.

   ```bash
   terraform init
   ```

1. (Optional) Run `terraform plan` to verify that state is configured correctly. You should see one change regarding the obervability dashboard.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent\_gateway\_authz\_fail\_open | If true, allow traffic through the Agent Gateway when an authz extension call fails. Set false in production. | `bool` | `true` | no |
| agent\_gateway\_dns\_peering\_config | Optional DNS peering for the Agent Gateway. Lets the gateway resolve the listed `domains` (each must end with a dot) against the target VPC's private Cloud DNS zones — required for the gateway to reach upstream MCP servers by hostname (e.g. `mcp.agent-gateway.sc-ccn.xyz.` records that point at the MCP internal LB). `target_project` defaults to `var.project_id` and `target_network` defaults to the self-link of the VPC this module creates; override only when peering against a VPC in a different project or network. Applied natively via `network_config.dns_peering_config` on the Agent Gateway resource. | <pre>object({<br>    domains        = list(string)<br>    target_project = optional(string)<br>    target_network = optional(string)<br>  })</pre> | `null` | no |
| agent\_gateway\_iap\_iam\_enforcement\_mode | Set to "DRY\_RUN" to put the Agent Gateway IAP authz extension into dry-run mode (IAM allow policies evaluated and logged but not blocking). Leave null (the default) to omit the metadata key, which matches the IAP default of enforcing. | `string` | `null` | no |
| agent\_gateway\_name | Name of the Agent Gateway resource (and prefix for its network attachment, authz extensions, and authz policies) | `string` | `"agent-gateway"` | no |
| agent\_gateway\_subnet\_cidr | CIDR for the Agent Gateway dedicated subnet. Min /28, RFC1918, must not overlap 10.0.0.0/24, 10.0.1.0/24, or 10.0.2.0/24 (Agent Gateway egress restrictions). | `string` | `"10.20.0.0/28"` | no |
| agent\_registry\_custom\_services | List of custom services to register in Agent Registry | <pre>list(object({<br>    id           = string<br>    display_name = string<br>    url          = string<br>    description  = optional(string)<br>  }))</pre> | <pre>[<br>  {<br>    "display_name": "Github",<br>    "id": "github",<br>    "url": "https://github.com"<br>  }<br>]</pre> | no |
| agent\_registry\_google\_apis | Map of Google API IDs to their display names to register in Agent Registry | `map(string)` | <pre>{<br>  "agentregistry": "Agent Registry",<br>  "aiplatform": "Vertex AI Platform",<br>  "cloudresourcemanager": "Cloud Resource Manager",<br>  "discoveryengine": "Discovery Engine",<br>  "global-discoveryengine": "Global Discovery Engine",<br>  "iap": "Identity-Aware Proxy",<br>  "logging": "Logging",<br>  "monitoring": "Monitoring",<br>  "oauth2": "OAuth2",<br>  "telemetry": "Telemetry",<br>  "trace": "Trace"<br>}</pre> | no |
| billing\_account | The ID of the billing account to associate this project with. | `string` | n/a | yes |
| bucket\_force\_destroy | When deleting a bucket, this boolean option will delete all contained objects. If false, Terraform will fail to delete buckets which contain objects. | `bool` | `false` | no |
| cloudbuild\_bucket\_name | Override the Cloud Build source bucket name. Defaults to <project\_id>\_cloudbuild, which matches the bucket gcloud/Cloud Build SDKs auto-pick when no --gcs-source-staging-dir is passed; overriding the name breaks that convenience. | `string` | `null` | no |
| dns\_zone\_domain | The domain name for the public DNS zone (must end with a dot, e.g., 'example.com.'). Certificate Manager validates the MCP LB cert against this zone. | `string` | `null` | no |
| dns\_zone\_name | The name of the existing Cloud DNS managed zone. If not provided, derived from dns\_zone\_domain. | `string` | `null` | no |
| enable\_model\_armor | Enable Model Armor template and IAM bindings | `bool` | `false` | no |
| enable\_model\_armor\_mcp\_floor\_setting | Enable Model Armor floor setting for MCP server protection (BigQuery MCP) | `bool` | `true` | no |
| enable\_model\_armor\_vertex\_ai | Enable Model Armor integration with Vertex AI (floor setting + IAM) | `bool` | `false` | no |
| enabled\_services | List of Google Cloud APIs to enable | `list(string)` | <pre>[<br>  "compute.googleapis.com",<br>  "storage.googleapis.com",<br>  "storage-api.googleapis.com",<br>  "storage-component.googleapis.com",<br>  "dns.googleapis.com",<br>  "containerregistry.googleapis.com",<br>  "artifactregistry.googleapis.com",<br>  "run.googleapis.com",<br>  "monitoring.googleapis.com",<br>  "logging.googleapis.com",<br>  "cloudtrace.googleapis.com",<br>  "cloudprofiler.googleapis.com",<br>  "servicenetworking.googleapis.com",<br>  "networkmanagement.googleapis.com",<br>  "networkservices.googleapis.com",<br>  "modelarmor.googleapis.com",<br>  "networksecurity.googleapis.com",<br>  "iam.googleapis.com",<br>  "iamcredentials.googleapis.com",<br>  "sts.googleapis.com",<br>  "cloudkms.googleapis.com",<br>  "binaryauthorization.googleapis.com",<br>  "secretmanager.googleapis.com",<br>  "iap.googleapis.com",<br>  "cloudresourcemanager.googleapis.com",<br>  "serviceusage.googleapis.com",<br>  "stackdriver.googleapis.com",<br>  "autoscaling.googleapis.com",<br>  "cloudbuild.googleapis.com",<br>  "certificatemanager.googleapis.com",<br>  "cloudquotas.googleapis.com",<br>  "aiplatform.googleapis.com",<br>  "dlp.googleapis.com",<br>  "telemetry.googleapis.com",<br>  "apphub.googleapis.com",<br>  "agentregistry.googleapis.com"<br>]</pre> | no |
| encrypt\_gcs\_bucket\_tfstate | Encrypt the bucket used for storing Terraform state files in the seed project. | `bool` | `true` | no |
| kms\_prevent\_destroy | If set to true, delete KMS keyring and keys when destroying the module; otherwise, destroying the module will fail if KMS keys are present. | `bool` | `true` | no |
| mcp\_internal\_dns\_zone | Private DNS zone hosting <service>.<domain> A records for the MCP Cloud Run<br>services. Attached to the VPC so workloads (and Agent Engine via DNS<br>peering) resolve internally.<br><br>`domain` MUST be a real subdomain (typically "mcp.<dns\_zone\_domain>") so<br>Certificate Manager can issue a Google-managed regional cert that the<br>Agent Gateway will validate. | <pre>object({<br>    name   = optional(string, "mcp-server-internal")<br>    domain = string<br>  })</pre> | `null` | no |
| mcp\_lb\_protocol | Front-end protocol for the MCP internal Application LB. With HTTPS, the LB<br>serves a Google-managed regional cert for *.mcp.<dns\_zone\_domain>; otherwise<br>it falls back to an auto-generated self-signed cert for *.<mcp\_internal\_dns\_zone.domain><br>(note: not validatable by Agent Gateway today). | `string` | `"HTTPS"` | no |
| mcp\_services | Map of MCP service name to deployment configuration. The map key becomes the Cloud Run service name AND the URL-mask token (e.g. legacy-dms.<mcp\_internal\_dns\_zone.domain> -> Cloud Run service 'legacy-dms'). | <pre>map(object({<br>    image              = string<br>    container_port     = optional(number, 8080)<br>    otel_service_name  = optional(string)<br>    min_instance_count = optional(number, 0)<br>    max_instance_count = optional(number, 3)<br>    cpu                = optional(string, "1")<br>    memory             = optional(string, "512Mi")<br>    env                = optional(map(string), {})<br>  }))</pre> | `{}` | no |
| mcp\_tool\_specs | Map of MCP service name -> path to its toolspec.json (relative to the terraform/ directory or absolute). Required for every key in var.mcp\_services; the toolspec is uploaded into the Agent Registry entry as the MCP server spec. Note: the var.mcp\_services key (which becomes the Agent Registry service ID and the LB hostname) does not need to match the source directory name (e.g. income-verification -> ../src/income-verification-api/toolspec.json). | `map(string)` | `{}` | no |
| model\_armor\_malicious\_uri\_enforcement | Malicious URI filter enforcement setting (ENABLED or DISABLED) | `string` | `"ENABLED"` | no |
| model\_armor\_pi\_jailbreak\_confidence | PI and jailbreak filter confidence level (LOW\_AND\_ABOVE, MEDIUM\_AND\_ABOVE, or HIGH) | `string` | `"LOW_AND_ABOVE"` | no |
| model\_armor\_pi\_jailbreak\_enforcement | PI and jailbreak filter enforcement setting (ENABLED or DISABLED) | `string` | `"ENABLED"` | no |
| model\_armor\_pii\_types | Info types whose findings the response Model Armor template's deidentify transformation replaces with the type-name placeholder. Model Armor's SDP filter still runs Google's built-in detectors (including PERSON\_NAME) regardless of this list, but only findings whose info type appears here are transformed — anything else is passed through to the agent unchanged. Keep identity fields the agent needs for downstream reasoning (e.g. PERSON\_NAME) OUT of this list. | `list(string)` | <pre>[<br>  "US_SOCIAL_SECURITY_NUMBER",<br>  "CREDIT_CARD_NUMBER",<br>  "PHONE_NUMBER",<br>  "EMAIL_ADDRESS",<br>  "PASSPORT",<br>  "DATE_OF_BIRTH",<br>  "MEDICAL_RECORD_NUMBER",<br>  "IP_ADDRESS",<br>  "STREET_ADDRESS"<br>]</pre> | no |
| model\_armor\_rai\_filters | RAI (Responsible AI) filter configurations. filter\_type can be: SEXUALLY\_EXPLICIT, HATE\_SPEECH, HARASSMENT, DANGEROUS. confidence\_level can be: LOW\_AND\_ABOVE, MEDIUM\_AND\_ABOVE, HIGH | <pre>list(object({<br>    filter_type      = string<br>    confidence_level = string<br>  }))</pre> | <pre>[<br>  {<br>    "confidence_level": "MEDIUM_AND_ABOVE",<br>    "filter_type": "HATE_SPEECH"<br>  },<br>  {<br>    "confidence_level": "MEDIUM_AND_ABOVE",<br>    "filter_type": "HARASSMENT"<br>  },<br>  {<br>    "confidence_level": "MEDIUM_AND_ABOVE",<br>    "filter_type": "SEXUALLY_EXPLICIT"<br>  }<br>]</pre> | no |
| model\_armor\_request\_template\_id | ID for the request-side Model Armor template (RAI + PI/jailbreak; no SDP). Wired into the Agent Gateway CONTENT\_AUTHZ extension as request\_template\_id. | `string` | `"agw-request-template"` | no |
| model\_armor\_response\_template\_id | ID for the response-side Model Armor template (RAI; SDP advanced\_config when model\_armor\_sdp\_enforcement = ENABLED). Wired into the Agent Gateway CONTENT\_AUTHZ extension as response\_template\_id. | `string` | `"agw-response-template"` | no |
| model\_armor\_sdp\_enforcement | Sensitive Data Protection filter enforcement setting (ENABLED or DISABLED) | `string` | `"ENABLED"` | no |
| model\_armor\_vertex\_ai\_cloud\_logging | Enable Cloud Logging for Vertex AI Model Armor sanitization | `bool` | `true` | no |
| model\_armor\_vertex\_ai\_inspect\_only | When true, Vertex AI uses INSPECT\_ONLY mode; when false, uses INSPECT\_AND\_BLOCK | `bool` | `false` | no |
| name\_prefix | Prefix for resource names | `string` | `"gateway"` | no |
| org\_id | GCP organization ID (numeric). Required for Agent Identity IAM bindings. | `string` | `null` | no |
| parent\_folder | The folder ID where the project will be created. | `string` | n/a | yes |
| platform\_admin\_members | List of IAM members granted roles: discoveryengine.admin always; modelarmor.admin and modelarmor.floorSettingsAdmin when enable\_model\_armor; aiplatform.user (e.g. ["user:admin@example.com"]) | `list(string)` | `[]` | no |
| primary\_subnet\_cidr | CIDR range for the primary subnet | `string` | `"10.0.0.0/20"` | no |
| project\_deletion\_policy | Project deletion policy. Possible values are: "PREVENT", "ABANDON", "DELETE". | `string` | `"DELETE"` | no |
| project\_id | The GCP project ID | `string` | n/a | yes |
| project\_number | The GCP project number | `string` | n/a | yes |
| proxy\_subnet\_cidr | CIDR range for the proxy-only subnet | `string` | `"10.9.0.0/24"` | no |
| psc\_interface\_dns\_zone | Private DNS zone for PSC Interface DNS peering. `domain` MUST end with a trailing dot. | <pre>object({<br>    name   = optional(string, "psc-interface-dns-zone")<br>    domain = string<br>  })</pre> | `null` | no |
| psc\_interface\_subnet\_cidr | CIDR for the PSC Interface subnet (min /28, must not overlap with psc\_subnet\_cidr) | `string` | `"10.11.0.0/28"` | no |
| psc\_subnet\_cidr | CIDR range for the Private Service Connect subnet | `string` | `"10.10.0.0/24"` | no |
| region | The GCP region for resources | `string` | `"us-central1"` | no |
| subnet\_name | Name of the primary subnet | `string` | `"mcp-subnet-us-central1"` | no |
| vpc\_name | Name of the VPC network | `string` | `"gateway-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| agent\_gateway\_id | Full resource ID of the Agent Gateway |
| agent\_gateway\_mtls\_endpoint | mTLS endpoint clients use to reach the Agent Gateway |
| agent\_gateway\_registry\_uri | URI of the project-local agent registry the gateway is bound to |
| agent\_gateway\_root\_certificates | Root certificates clients use to validate the Agent Gateway mTLS endpoint |
| agent\_gateway\_service\_extensions\_service\_account | Service account the Agent Gateway uses to call out to authz extensions |
| agent\_gateway\_subnet\_self\_link | Self link of the Agent Gateway dedicated co-location subnet |
| agent\_mcp\_invoker\_email | Email of the SA agents impersonate when invoking MCP Cloud Run services. Pass to deploy\_agent.py via --mcp-invoker-sa or $MCP\_INVOKER\_SA\_EMAIL. |
| agent\_registry\_service\_ids | Map of registered Agent Registry service resource IDs, keyed by service\_id |
| artifact\_registry\_id | The Artifact Registry repository ID |
| artifact\_registry\_url | The Artifact Registry repository URL for docker push/pull |
| mcp\_cloud\_run\_ingress\_annotation | Cloud Run v1 ingress annotation value to use when rendering cloudrun/*.yaml.tmpl. |
| mcp\_internal\_dns\_domain | Domain name (with trailing dot) of the MCP servers private DNS zone |
| mcp\_internal\_dns\_names | Map of MCP service key to its private DNS name (<service>.<domain>). |
| mcp\_internal\_dns\_zone\_name | Cloud DNS managed zone name for the MCP servers private DNS |
| mcp\_internal\_lb\_ip | Internal IP address of the MCP services Application LB. |
| mcp\_service\_account\_emails | Map of MCP service key to runtime service account email |
| mcp\_service\_names | Map of MCP service key to Cloud Run service name |
| mcp\_service\_urls | Map of MCP service key to Cloud Run *.run.app URL (only reachable via the internal LB) |
| model\_armor\_deidentify\_template\_id | DLP de-identify template ID referenced by the response template's advanced SDP config (null when model\_armor\_sdp\_enforcement = DISABLED) |
| model\_armor\_inspect\_template\_id | DLP inspect template ID referenced by the response template's advanced SDP config (null when model\_armor\_sdp\_enforcement = DISABLED) |
| model\_armor\_request\_template\_id | Request-side Model Armor template ID |
| model\_armor\_request\_template\_name | Request-side Model Armor template full resource name |
| model\_armor\_response\_template\_id | Response-side Model Armor template ID |
| model\_armor\_response\_template\_name | Response-side Model Armor template full resource name |
| model\_armor\_service\_account | Service Extensions service account (gcp-sa-dep) used by the Agent Gateway to call Model Armor |
| model\_armor\_service\_agent\_email | Model Armor service agent (gcp-sa-modelarmor) granted DLP read access (null when model\_armor\_sdp\_enforcement = DISABLED) |
| network\_self\_link | The self-link of the VPC network |
| project\_id | Project ID |
| psc\_interface\_dns\_domain | Domain name for PSC Interface DNS peering (ends with a dot) |
| psc\_interface\_dns\_peering\_domain | DNS domain for PSC Interface DNS peering (pass to deploy\_agent.py --dns-peering-domain) |
| psc\_interface\_dns\_zone\_name | DNS zone name for PSC Interface DNS peering |
| psc\_interface\_network\_attachment\_id | Network attachment ID for PSC Interface (pass to deploy\_agent.py --network-attachment) |
| psc\_interface\_network\_attachment\_name | Network attachment name for PSC Interface |
| psc\_subnet\_id | The ID of the Private Service Connect subnet |
| psc\_subnet\_self\_link | The self-link of the Private Service Connect subnet |
| regional\_certificate\_name | Name of the regional Google-managed certificate. |
| subnet\_id | The ID of the primary subnet |
| subnet\_name | Name of the primary subnet |
| subnet\_self\_link | The self-link of the primary subnet |
| vpc\_id | The ID of the VPC network |
| vpc\_name | The name of the VPC network |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->