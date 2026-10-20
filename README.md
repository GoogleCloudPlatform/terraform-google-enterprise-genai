# terraform-google-enterprise-agent-platform

## Overview

This repository provides modular Terraform blueprints for configuring, deploying, and governing the **Enterprise Agent Platform** on Google Cloud. It enables organizations to build, deploy, scale, and secure AI agents, Model Context Protocol (MCP) servers, and enterprise AI workloads using the Cloud Foundation Toolkit (CFT).

- **Agent Governance & Gateway:** Establishes centralized ingress and egress networking for AI agents through Agent Gateway, enforcing identity-based access control (IAM/IAP), policy routing, and Service Extensions.
- **Agent Runtime & Tools (MCP):** Provides managed execution environments (Agent Engine) and deploys modular Model Context Protocol (MCP) server tools on Cloud Run behind Internal Application Load Balancers with Serverless NEGs.
- **Agent Registry:** Manages a centralized catalog of approved enterprise agents, tools, and third-party MCP servers.
- **AI Security Guardrails (Model Armor):** Integrates Model Armor via Service Extensions to screen content, block prompt injections, prevent jailbreaks, and sanitize sensitive data.
- **Agent Observability:** Delivers dashboards and Log Analytics queries for end-to-end tracing, auditing, and performance monitoring of agent interactions.
- **Organization Policies:** Configures AI-specific Organization Policies for resource restrictions, allowed locations, and Workbench/notebook access modes.
- **KMS & CMEK Encryption:** Establishes Cloud KMS keyrings with Customer-Managed Encryption Keys (CMEK) to encrypt Logging buckets, AI environments, Service Catalog storage, and Artifact repositories.
- **Networking & Private DNS:** Configures VPC networks, private DNS zones (including `notebooks.googleusercontent.com` and `restricted.googleapis.com`), PSC endpoints, and firewall rules (`allow_all_ingress_ranges` and `allow_all_egress_ranges`).
- **VPC Service Controls:** Attaches Agent, Machine Learning, Logging, and KMS projects to controlled VPC-SC security perimeters (supporting both enforced and dry-run modes).
- **Service Catalog:** Establishes a Service Catalog with automated Cloud Build CI/CD pipelines to package and distribute reusable Terraform modules across the organization.
- **Artifact Publishing:** Creates Artifact Registry repositories with automated Cloud Build pipelines configured to build, tag, and manage custom container images.

## Usage

Basic usage of the Enterprise Agent Platform modules in this repository is as follows:

```hcl
# 1. Observability: Dashboards and Log Analytics
module "observability" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/observability?ref=main"

  project_id       = var.project_id
  enable_logs_sink = true
}

# 2. Networking: Dedicated VPC, subnets, and PSC interfaces
module "networking" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/networking?ref=main"

  project_id                = var.project_id
  region                    = var.region
  vpc_name                  = "agent-vpc"
  primary_subnet_cidr       = "10.0.0.0/24"
  proxy_subnet_cidr         = "10.0.1.0/24"
  agent_gateway_subnet_cidr = "10.0.2.0/24"
}

# 3. AI Security & Guardrails (Model Armor)
module "model_armor" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/model_armor?ref=main"

  project_id         = var.project_id
  region             = var.region
  enable_model_armor = true
}

# 4. Agent Runtime Environment (Agent Engine)
module "agent_engine" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/agent_engine?ref=main"

  project_id                = var.project_id
  project_number            = var.project_number
  org_id                    = var.org_id
  terraform_service_account = var.terraform_service_account
}

# 5. MCP Server Tools on Cloud Run
module "mcp_services" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/mcp_cloud_run?ref=main"

  project_id       = var.project_id
  region           = var.region
  services         = var.mcp_services
  invoker_sa_email = module.agent_engine.agent_mcp_invoker_email
}

# 6. Internal Load Balancer with Serverless NEGs for MCP Services
module "mcp_internal_lb" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/mcp_internal_lb?ref=main"

  project_id        = var.project_id
  region            = var.region
  network_self_link = module.networking.network_self_link
  subnet_self_link  = module.networking.subnet_self_link
}

# 7. Agent Gateway: Network and Governance entry/exit point
module "agent_gateway" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/agent_gateway?ref=main"

  project_id                     = var.project_id
  region                         = var.region
  name                           = "agent-gateway"
  network_self_link              = module.networking.network_self_link
  agent_gateway_subnet_self_link = module.networking.agent_gateway_subnet_self_link
}

# 8. Agent Registry: Catalog of approved tools and MCP servers
module "agent_registry" {
  source = "git::https://github.com/GoogleCloudPlatform/terraform-google-enterprise-genai.git//modules/agent_registry?ref=main"

  project_id = var.project_id
  region     = var.region
}
```

> **Note:** This repository is under active development. Pin to a specific release tag when available for production use.

**GCP Locations:** Considerations for configuring regions across the modules:
- `region` / `default_region`: Defines the primary GCP region where regional resources are deployed (e.g., Agent Gateway, Cloud Run MCP services, Internal Application Load Balancers, Model Armor templates, VPC subnets, and DNS zones). **Must be a single supported region** (e.g., `us-central1`).
- `keyring_regions`: Used when enabling Customer-Managed Encryption Keys (CMEK) via Cloud KMS, defining the list of regions for keyrings (e.g., in the standalone baseline). This list must include the primary region to ensure encryption coverage for Logging, Service Catalog, Artifact Publishing, and AI resources.

## Modules

The repository contains modular components organized under [`modules/`](./modules):

### Agent Platform & Security
- [`agent_engine`](./modules/agent_engine): Managed runtime environment for deploying and executing AI agents.
- [`agent_gateway`](./modules/agent_gateway): Centralized ingress/egress networking and security gateway for agent interactions.
- [`agent_registry`](./modules/agent_registry): Centralized catalog for approved agents, tools, and MCP servers.
- [`mcp_cloud_run`](./modules/mcp_cloud_run): Deploys Model Context Protocol (MCP) server tools on Cloud Run.
- [`mcp_internal_lb`](./modules/mcp_internal_lb): Internal Application Load Balancer with Serverless NEGs for MCP services.
- [`model_armor`](./modules/model_armor): AI security guardrails against prompt injection, jailbreaks, and sensitive data leakage.
- [`observability`](./modules/observability): Dashboards and Log Analytics for tracing and auditing agent traffic.
- [`certificates`](./modules/certificates): Google-managed SSL certificates for internal load balancers.

### Infrastructure & Foundations
- [`service_controls`](./modules/service_controls): VPC Service Controls security perimeter configuration.
- [`ml_org_policies`](./modules/ml_org_policies): Organization Policies for AI platform access control and restrictions.
- [`networking`](./modules/networking): VPC networking and subnets for agent infrastructure.
- [`dns`](./modules/dns): Private DNS managed zones and routing.
- [`ml_dns_notebooks`](./modules/ml_dns_notebooks): DNS configurations for Vertex AI Workbench instances.
- [`ml_env`](./modules/ml_env): Dedicated project environment for AI and Machine Learning workloads.
- [`publish_artifacts`](./modules/publish_artifacts): Artifact Registry and Cloud Build image build pipelines.
- [`service_catalog`](./modules/service_catalog): CI/CD pipeline for automated Terraform module distribution.

## Examples

- [mortgage-agent](./examples/mortgage-agent)
  - End-to-end reference architecture for the Gemini Enterprise Agent Platform featuring an agent built with the Agent Development Kit (ADK).
  - Deploys internal tools as Model Context Protocol (MCP) servers on Cloud Run exposed through an Internal Application Load Balancer with Serverless NEGs.
  - Configures Agent Gateway in egress mode to enforce identity-based access control (IAM/IAP) and policy routing.
  - Integrates Model Armor AI security guardrails via Service Extensions to screen interactions against prompt injection and sensitive data leakage.
  - Includes centralized Agent Observability dashboards backed by Log Analytics for tracing and auditing agent traffic.

- [standalone](./examples/standalone)
  - Creates all required projects and resources through the `harness` configuration.
  - End-to-end deployment of the platform infrastructure, including Organization Policies, KMS keyrings and crypto keys, networking with private DNS zones, VPC Service Controls, Service Catalog pipelines, and Artifact Publishing pipelines.

- [genai-rag-multimodal](./examples/genai-rag-multimodal)
  - Multimodal RAG by performing Q&A over a financial document filled with both text and images.
  - Use RAGAS for RAG chain evaluation.

- [machine-learning-pipeline](./examples/machine-learning-pipeline)
  - This example, adds an interactive coding and experimentation, deploying the Vertex Workbench for data scientists.
  - The step will guide you through creating a ML pipeline using a notebook on Google Vertex AI Workbench Instance.
  - After promoting the ML pipeline, it is triggered by Cloud Build upon staging branch merges, trains and deploys a model using the census income dataset.
  - Model deployment and monitoring occur in the `prod` environment.
  - Following successful pipeline runs, a new model version is deployed for A/B testing.
