This guide is designed for **AI coding assistants, LLMs, and autonomous agents** contributing to the `terraform-google-enterprise-genai` repository. It outlines the architectural mental model, directory structure, development workflows, security guardrails, and verification procedures required to generate high-quality, production-ready contributions.

---

## 1. Blueprint Purpose & Architectural Philosophy

This repository implements the Google Cloud Platform (GCP) **Enterprise Agent Platform blueprint** (`terraform-google-enterprise-genai`). It provides modular, opinionated, and production-ready Terraform blueprints for configuring, deploying, scaling, and governing AI agents, Model Context Protocol (MCP) servers, and enterprise AI workloads using the Cloud Foundation Toolkit (CFT).

*   **Centralize Agent Ingress, Egress & Governance**: Enforce identity-based access control (IAM/IAP), policy routing, and Service Extensions for AI agent interactions via Agent Gateway.
*   **Standardize Agent Execution & MCP Tooling**: Provide managed execution environments (Agent Engine / Agent Runtime with ADK) and deploy modular Model Context Protocol (MCP) server tools on Cloud Run behind Internal Application Load Balancers with Serverless NEGs.
*   **Enforce AI Security Guardrails by Default**: Integrate Model Armor via Service Extensions to screen content, block prompt injections, prevent jailbreaks, and sanitize sensitive data (DLP de-identification).
*   **Centralize Agent Registry & Observability**: Maintain an authoritative catalog of approved enterprise agents, internal tools, and third-party MCP servers (Agent Registry), and deliver end-to-end tracing, auditing, and monitoring dashboards backed by Log Analytics.
*   **Enforce Enterprise Isolation & Compliance**: Zero-trust networking, Private Service Connect (PSC), VPC Service Controls (VPC-SC), private DNS zones, Cloud KMS Customer-Managed Encryption Keys (CMEK), and AI-specific Organization Policies.
*   **Automate Infrastructure & Artifact Distribution**: Establish automated Cloud Build CI/CD pipelines to package and distribute reusable Terraform modules via Service Catalog and container images via Artifact Registry.
*   **Support Interactive GenAI & Multimodal RAG**: Secure Vertex AI Workbench environments with Private Service Connect and Vertex AI Vector Search for enterprise Retrieval-Augmented Generation.
*   **Support Machine Learning Pipelines**: Provide end-to-end ML training and deployment lifecycle workflows (*Note: The `machine-learning-pipeline` example is pinned to foundation v0.11 and is not compatible with the current platform version of this repository*).

---

## 2. Platform Architecture & Blueprint Composition

This repository is organized as a modular, composable platform. When reasoning about this codebase, AI agents should reference the functional tiers, their constituent modules, and their operational scopes:

| Architectural Tier | Path / Module | Responsibility & Scope | Target Audience |
| :--- | :--- | :--- | :--- |
| **Foundations & Security Baseline** | `modules/networking`<br>`modules/dns`<br>`modules/ml_dns_notebooks`<br>`modules/service_controls`<br>`modules/ml_org_policies`<br>`test/setup/` | Core network and security infrastructure: dedicated VPC networks with primary, proxy-only (`envoy`), PSC interface, and gateway co-location subnets; private Cloud DNS zones (`*.notebooks.googleusercontent.com`, `restricted.googleapis.com`, MCP private domains); Cloud KMS keyrings with CMEK; VPC Service Controls perimeters (dry-run & enforced); and AI Organization Policies (`ainotebooks.restrictPublicIp`, `gcp.restrictNonCmekServices`, TLS versions). | Platform & Security Admin |
| **Agent Execution & Tooling (MCP)** | `modules/agent_engine`<br>`modules/mcp_cloud_run`<br>`modules/mcp_internal_lb`<br>`modules/certificates` | Agent execution runtime (Agent Engine / Vertex AI Reasoning Engine with ADK) and containerized Model Context Protocol (MCP) servers deployed on Cloud Run, fronted by an Internal Application Load Balancer with Serverless NEGs, URL mask routing, and Google-managed regional SSL certificates via Certificate Manager (DNS-01 validation). | AI Platform Engineer / Agent Developer |
| **Governance, Guardrails & Registry** | `modules/agent_gateway`<br>`modules/model_armor`<br>`modules/agent_registry` | Centralized Agent Gateway (egress/ingress modes) enforcing identity-based access control via Identity-Aware Proxy (`REQUEST_AUTHZ` Service Extension with CEL conditions); Model Armor content screening (`CONTENT_AUTHZ` Service Extension for prompt injection, jailbreaks, RAI filters, and DLP SSN/PII de-identification); and an authoritative Agent Registry for approved tools and MCP endpoints. | Security Admin / AI Governance |
| **Observability & Artifact CI/CD** | `modules/observability`<br>`modules/service_catalog`<br>`modules/publish_artifacts` | End-to-end telemetry via Log Analytics views and Cloud Monitoring dashboards (OpenTelemetry spans for Agent Gateway, IAP, and Model Armor); Service Catalog CI/CD pipelines distributing reusable Terraform solutions (Notebooks, BigQuery, Composer, Pub/Sub, Storage); and Artifact Registry automated container image build triggers. | Platform Admin / AI Ops |
| **Reference Workload Implementations** | `examples/mortgage-agent/`<br>`examples/standalone/`<br>`examples/genai-rag-multimodal/`<br>`examples/machine-learning-pipeline/`<br>`modules/ml_env` | End-to-end implementations: ADK agent with Cloud Run MCP tools behind Agent Gateway and Model Armor (`mortgage-agent`); 6-project baseline harness (`standalone`); interactive Vertex AI Workbench with Vector Search over PSC (`genai-rag-multimodal`); dedicated ML project environments (`ml_env`); and ML lifecycle pipeline (*legacy v0.11*). | Solution Architect / GenAI Developer |

---

## 3. Directory Layout & Key Lookup

```
terraform-google-enterprise-genai/
├── modules/                        # Reusable Terraform platform modules
│   ├── agent_engine/               # Managed runtime environment and IAM permissions for deploying and executing ADK AI agents
│   ├── agent_gateway/              # Centralized ingress/egress gateway enforcing IAM/IAP and Model Armor Service Extensions
│   ├── agent_registry/             # Centralized catalog of approved enterprise agents, tools, and third-party MCP servers
│   ├── certificates/               # Regional Google-managed SSL certificates via Certificate Manager with DNS-01 validation
│   ├── dns/                        # Private Cloud DNS managed zones and VPC routing configurations
│   ├── mcp_cloud_run/              # Containerized Model Context Protocol (MCP) server tools deployed on Cloud Run
│   ├── mcp_internal_lb/            # Internal Application Load Balancer with Serverless NEGs and URL mask routing for MCP tools
│   ├── ml_dns_notebooks/           # Private DNS endpoints (*.notebooks.googleusercontent.com) for Vertex AI Workbench via PSC
│   ├── ml_env/                     # Dedicated project environment for Vertex AI, Cloud Storage, Secret Manager, and Pub/Sub
│   ├── ml_org_policies/            # AI Organization Policies (restricting public IPs, non-CMEK services, TLS versions, and root access)
│   ├── model_armor/                # AI security guardrails against prompt injection, jailbreaks, RAI violations, and DLP/PII leakage
│   ├── networking/                 # Dedicated VPC network, subnets (primary, proxy-only Envoy, PSC interface, gateway), and firewall rules
│   ├── observability/              # Cloud Logging sinks, Log Analytics queries, and Monitoring dashboards for agent traffic and tracing
│   ├── publish_artifacts/          # Artifact Registry repository and automated Cloud Build container image build pipelines
│   ├── service_catalog/            # Service Catalog repository and Cloud Build CI/CD pipeline distributing reusable Terraform modules
│   └── service_controls/           # VPC Service Controls security perimeters (supporting enforced and dry-run modes)
├── examples/                       # End-to-end reference implementations
│   ├── mortgage-agent/             # ADK agent with Cloud Run MCP tools, Agent Gateway egress, Model Armor guardrails, and observability
│   ├── standalone/                 # 6-project baseline harness (Seed, KMS, Logging, ML, Artifacts, Service Catalog) with KMS CMEK & VPC-SC
│   ├── genai-rag-multimodal/       # Multimodal RAG with Vertex AI Workbench and Vector Search over Private Service Connect (PSC)
│   └── machine-learning-pipeline/  # End-to-end ML training, deployment, and A/B testing pipeline (pinned to legacy foundation v0.11)
├── scripts/                        # Automation and utility scripts
│   ├── set-tfc-backend-and-remote.sh # Script to configure Terraform Cloud backend and remote execution
│   └── validate-requirements.sh    # Script to validate local tool versions and prerequisites
├── build/                          # Multi-provider CI/CD pipelines & automation scripts
│   ├── tf-wrapper.sh               # Terraform wrapper script for workspace and state management
│   ├── cloudbuild-tf-plan.yaml     # Cloud Build Terraform plan pipeline
│   ├── cloudbuild-tf-apply.yaml    # Cloud Build Terraform apply pipeline
│   ├── lint.cloudbuild.yaml        # Cloud Build linting and validation pipeline
│   ├── int.cloudbuild.yaml         # Cloud Build integration test execution pipeline
│   ├── github-tf-pull-request.yaml # GitHub Actions Terraform plan pipeline
│   ├── github-tf-apply.yaml        # GitHub Actions Terraform apply pipeline
│   ├── gitlab-ci.yml               # GitLab CI Terraform pipeline
│   ├── Jenkinsfile                 # Jenkins Terraform pipeline
│   └── run_gcp_auth.sh             # GCP authentication script used by the GitLab CI pipeline
├── test/                           # Quality assurance and testing harness
│   ├── setup/                      # Terraform harness provisioning CI test environment and IAM permissions
│   ├── integration/                # Blueprint-test integration tests written in Go (mortgage-agent, standalone, appsource, testutils)
│   └── clean_org.sh                # Cleanup script for test organization resources
├── docs/                           # Documentation guides
│   ├── FAQ.md                      # Frequently asked questions and named branch definitions
│   ├── GLOSSARY.md                 # Definition of capitalized foundation and platform terms
│   ├── TROUBLESHOOTING.md          # Solutions for common Terraform, IAM, and quota issues
│   ├── change_resource_hierarchy.md# Guide for customizing Cloud Resource Manager folder hierarchies
│   ├── upgrading_to_v2.0.md        # Upgrade guidance and breaking changes for platform v2.0
│   └── upgrading_to_v3.0.md        # Upgrade guidance and breaking changes for platform v3.0
├── AGENTS.md                       # Architectural guide, coding conventions, and workflows for AI agents and developers
├── CHANGELOG.md                    # Release history, bug fixes, and feature additions across versions
├── CODEOWNERS                      # Code ownership mapping for pull request reviews
├── CONTRIBUTING.md                 # Contribution guidelines, development standards, and CLA requirements
├── Dockerfile-dev                  # Dockerfile defining the local container development environment
├── ERRATA.md                       # Known issues, provider workarounds, and errata
├── LICENSE                         # Apache 2.0 open-source software license
├── Makefile                        # Docker targets for linting (test_lint), docs generation, and integration testing
├── README.md                       # Primary repository overview, architectural summary, module list, and usage examples
└── renovate.json                   # Automated dependency management configuration
```

---

## 4. Agent Working Rules & Coding Conventions

When generating or updating code, AI agents MUST strictly adhere to the following standards:

### 4.1. Terraform Conventions
*   **Formatting**: Always run `terraform fmt -recursive` on modified Terraform directories.
*   **Explicit Types & Descriptions**: Every `variable` must have an explicit `type` definition and an informative `description`. Every `output` must have an informative `description`.
*   **No Hardcoded Resource IDs**: Never hardcode Project IDs, VPC names, or Service Account emails. Parameterize them via variables or derive them from data sources/outputs.
*   **Documentation Hooks**: Do not edit content inside `<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->` blocks manually. These are generated by `terraform-docs` (via `make docker_generate_docs`).
*   **Version Pinning**: Maintain consistent provider version constraints across `versions.tf` (`>= 7.16.0` for `google` / `google-beta`, `>= 7.39.0` in `agent_gateway`, `agent_registry`, and `mortgage-agent`, `>= 1.3` for Terraform core).

### 4.2. Security, IAM & AI Guardrails (Strict Enforcement)
*   **Principle of Least Privilege**: Never assign broad administrative roles (`roles/owner`, `roles/editor`). Use scoped roles for platform service accounts (`roles/run.invoker`, `roles/modelarmor.calloutUser`, `roles/modelarmor.user`, `roles/aiplatform.user`).
*   **Agent Identity & IAP Authorization**:
    *   Deploy agents with Agent Identity enabled (`--enable-agent-identity`) for mTLS-authenticated execution.
    *   Enforce tool egress authorization via Identity-Aware Proxy (`REQUEST_AUTHZ` Service Extension) with `roles/iap.egressor` and Common Expression Language (CEL) conditions.
*   **AI Guardrails (Model Armor & DLP)**:
    *   Attach Model Armor templates (`CONTENT_AUTHZ` Service Extension) to screen requests for prompt injection, jailbreaks, and RAI violations.
    *   Enforce Sensitive Data Protection (SDP/DLP) de-identification templates to sanitize SSN and sensitive PII from model responses.
*   **Private Connectivity**:
    *   MCP Cloud Run services must restrict ingress to internal load balancing (`internal-and-cloud-load-balancing`).
    *   Agent Gateway must egress through dedicated co-location subnets (`agent_gateway_subnet_cidr`) via PSC network attachments.
    *   Vertex AI Workbench instances must prohibit public IPs (`ainotebooks.restrictPublicIp`) and route via Private Service Connect.
*   **VPC Service Controls (VPC-SC) & CMEK**:
    *   Support execution inside VPC-SC perimeters (dry-run and enforced modes).
    *   Support Cloud KMS Customer-Managed Encryption Keys (CMEK) for Storage, Logging, Artifacts, and Vertex AI.
*   **No Plaintext Secrets**: Store all API tokens, credentials, and OAuth secrets in Secret Manager.

### 4.3. Go & Integration Test Conventions (`test/integration/`)
*   **Framework**: Integration tests are written in Go using CFT [blueprint-test](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/main/infra/blueprint-test).
*   **Formatting**: Format all Go files with `gofmt -s -w <file.go>`.
*   **Test Isolation**: Tests must create unique resource names or utilize random prefixes/suffixes to prevent collision during concurrent CI test runs.

### 4.4. Agent, MCP & Workload Conventions (`examples/`)
*   **Agent Development Kit (ADK) & Runtime**: Structure Python agents under `src/` using `uv` (`pyproject.toml`, `deploy_agent.py`) and deploy to Agent Runtime (Vertex AI Reasoning Engine) with explicit networking and identity flags.
*   **Model Context Protocol (MCP) Tools**: Every Cloud Run MCP tool must provide a valid `toolspec.json` registered in Agent Registry and use templated manifests (`cloud_run/*.yaml.tmpl`) deployed via Skaffold.
*   **OpenTelemetry Instrumentation**: Emit OpenTelemetry spans across agent code and MCP tools for end-to-end tracing through Agent Gateway, IAP, and Model Armor in Log Analytics.
*   **Interactive Notebooks & RAG (`genai-rag-multimodal`)**: Parameterize Jupyter Notebooks with Terraform outputs (PSC IP, Vector Search endpoint, KMS key) without hardcoding environment values.
*   **Service Catalog & Container Assets (`standalone`)**: Maintain modular Terraform solutions and Dockerfiles under `assets/` integrated with Cloud Build triggers.

---

## 5. Common Development Workflows

### Workflow A: Adding or Modifying a Platform Module (`modules/`)
1. **Implement Module Resources**: Add or update resources in `modules/<module-name>/main.tf`, `variables.tf`, and `outputs.tf`.
2. **Format Code**: Run `terraform fmt -recursive` on the modified module directory.
3. **Generate Documentation**: Run `make docker_generate_docs` to automatically populate input/output markdown tables inside `modules/<module-name>/README.md`.
4. **Run Lint Checks**: Execute `make docker_test_lint` to validate Terraform syntax, Shell scripts (`shellcheck`), and YAML manifests.
5. **Update Integration Tests**: Add or update the corresponding Go integration test suite under `test/integration/`.

### Workflow B: Adding or Updating an Example Scenario (`examples/`)
1. **Define Infrastructure Stack**: Implement the Terraform configuration (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`) referencing platform modules.
2. **Provide Sample Configuration**: Include a comprehensive `terraform.example.tfvars` file documenting all required and optional input variables.
3. **Package Workload Assets**: Include scenario-specific workload assets (e.g., ADK Python code under `src/`, MCP tool manifests with Skaffold, Jupyter notebooks, or Service Catalog assets).
4. **Enforce Enterprise Security**: Ensure support for Private Service Connect (PSC), VPC Service Controls (VPC-SC) perimeters, and Cloud KMS Customer-Managed Encryption Keys (CMEK).
5. **Support Remote State Backend**: Provide a `backend.tf.example` file and migration procedures (`terraform init -migrate-state`) for Google Cloud Storage backends.
6. **Document the Scenario**: Author a detailed `README.md` explaining prerequisites, architecture overview, step-by-step deployment, verification procedures, and resource cleanup instructions.

### Workflow C: Code Linting & Plan Validation
1. **Lint Code**: Execute `make docker_test_lint` to validate Terraform, Shell, YAML, and Go formatting and syntax.
2. **Validate Agent & MCP Code**: Run Python unit test suites via `uv run pytest` across agent and MCP tool services.
3. **Validate Plans & Test Integration**: Run scenario integration tests (`test/integration/`) to verify generated Terraform plans and ensure deployments pass without execution errors.

---

## 6. Developer Tooling & Verification Commands

Agents and contributors should use the following tools and commands to validate changes:

### 1. Code Formatting
```bash
# Format Terraform code across the entire repository
terraform fmt -recursive

# Format Go test code
gofmt -s -w test/
```

### 2. Linting & Validation (Docker Developer Tools)
```bash
# Execute lint checks across Terraform, Shell scripts, and YAML manifests
make docker_test_lint

# Generate module documentation tables
make docker_generate_docs
```

### 3. Running Integration Tests Locally

Integration tests require a test harness provisioned via `test/setup/`.

#### Step 1: Configure Test Variables (`test/setup/terraform.tfvars`)
Create a `terraform.tfvars` file inside `test/setup/` with the required parameters:
```hcl
org_id          = "012345678901"
folder_id       = "123456789012"
billing_account = "XXXXXX-YYYYYY-ZZZZZZ"
group_email     = "gcp-admins@example.com"
```

#### Step 2: Provision Harness & Run Tests
```bash
# 1. Provision test harness environment
make docker_test_prepare

# 2. Run specific blueprint-test integration test suites
make docker_run
cd test/integration
cft test run <TEST_NAME> --stage init --verbose --test-dir /workspace/test/integration
cft test run <TEST_NAME> --stage apply --verbose --test-dir /workspace/test/integration
cft test run <TEST_NAME> --stage verify --verbose --test-dir /workspace/test/integration
cft test run <TEST_NAME> --stage destroy --verbose --test-dir /workspace/test/integration
make docker_test_integration

# 3. Clean up test harness environment
make docker_test_cleanup
```

### 4. Running Agent & MCP Unit Tests (Python / pytest)
```bash
# Run agent logic and tool unit tests
cd examples/mortgage-agent/src/mortgage_agent
uv run pytest

# Run individual MCP service unit tests
cd ../corporate-email && uv run pytest
cd ../income-verification-api && uv run pytest
cd ../legacy-dms && uv run pytest
```

### 5. Interactive Container Development
```bash
# Enter the developer-tools container for local testing
make docker_run
```

---

## 7. Pre-Commit Verification Checklist for Agents
Before completing any task or proposing changes, verify that:

- [ ] `terraform fmt -recursive` runs cleanly without formatting errors.
- [ ] All new variables have explicit `type` definitions and meaningful `description` strings, and all new outputs have meaningful `description` strings.
- [ ] No hardcoded GCP project IDs, credentials, or sensitive secrets exist in `.tf`, `.tfvars`, `.yaml`, `.json`, or `.py` files.
- [ ] IAM roles strictly follow the Principle of Least Privilege.
- [ ] Any modified module has its documentation updated (`README.md` inputs/outputs tables).
- [ ] Go test files follow `gofmt` style and compile without errors (`cd test/integration && go vet ./...`).
- [ ] Python agent and MCP tool code pass tests (`uv run pytest`).
- [ ] Commit descriptions follow the Conventional Commits standard (`feat:`, `fix:`, `feat!:`, or `fix!:` summary line + explanatory "Why" body).
- [ ] Documentation updates comply with the [Google Developer Documentation Style Guide](https://developers.google.com/style).

---

## 8. Standards & Reference Links
*   **Documentation Style Guide**: [Google Developer Documentation Style Guide](https://developers.google.com/style)
*   **CL / Commit Guidelines**: [Google Engineering Practices on Writing Good CL Descriptions](https://google.github.io/eng-practices/review/developer/cl-descriptions.html)
*   **Code Review Speed**: [Google Engineering Practices on Code Review Speed](https://google.github.io/eng-practices/review/reviewer/speed.html)
*   **Cloud Foundation Toolkit (CFT)**: [CFT Overview](https://cloud.google.com/foundation-toolkit)
*   **CFT Blueprint Test Framework**: [CFT blueprint-test](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/main/infra/blueprint-test) (and [Go package documentation](https://pkg.go.dev/github.com/GoogleCloudPlatform/cloud-foundation-toolkit/infra/blueprint-test))
*   **Model Context Protocol (MCP)**: [MCP Specification](https://modelcontextprotocol.io)
*   **Troubleshooting Guide**: Consult [`docs/TROUBLESHOOTING.md`](./docs/TROUBLESHOOTING.md) for known edge cases and resolutions.
*   **Errata & Known Issues**: Consult [`ERRATA.md`](./ERRATA.md) for provider workarounds and platform notes.
*   **Platform Glossary**: Consult [`docs/GLOSSARY.md`](./docs/GLOSSARY.md) for definitions of platform terms.
