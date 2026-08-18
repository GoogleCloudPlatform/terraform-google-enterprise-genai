# Integration tests

Blueprint Test (`cft test run`) on Cloud Build, stages `init` → `apply` → `verify` → `destroy`.

`dns_zone_domain` is always required (MCP hosts are `*.mcp.<domain>`). Choose **one** certificate path:

| Path | When to use | Extra vars |
|---|---|---|
| **A. Existing cert** | Google (or you) already created a regional Certificate Manager cert | `TF_VAR_mcp_ssl_certificate_id` |
| **B. Issue on apply** | You have a **delegated** public Cloud DNS zone in the test project | `TF_VAR_dns_zone_name` |

Both need a public CA cert covering `mcp.<dns_zone_domain>` and `*.mcp.<dns_zone_domain>`. Path A skips DNS-01; path B writes DNS-01 records and waits for Google-managed issuance.

## Prerequisites

- A GCP project with billing
- Org/project IAM from `examples/mortgage_agent/README.md`
- Service account JSON in `SERVICE_ACCOUNT_JSON` (or Application Default Credentials)

```bash
export TF_VAR_org_id="YOUR_ORG_ID"
export TF_VAR_project_id="YOUR_PROJECT_ID"
export TF_VAR_project_number="YOUR_PROJECT_NUMBER"
export TF_VAR_dns_zone_domain="YOUR_PUBLIC_DOMAIN."   # trailing dot
```

Path A:

```bash
export TF_VAR_mcp_ssl_certificate_id="projects/YOUR_PROJECT_ID/locations/us-central1/certificates/CERT_NAME"
```

Path B:

```bash
export TF_VAR_dns_zone_name="YOUR_CLOUD_DNS_ZONE_NAME"
# leave TF_VAR_mcp_ssl_certificate_id unset
```

## Local (Docker)

```bash
make docker_test_prepare
make docker_run
# inside the container:
cft test run TestMortgageAgent --stage init --verbose
cft test run TestMortgageAgent --stage apply --verbose
cft test run TestMortgageAgent --stage verify --verbose
cft test run TestMortgageAgent --stage destroy --verbose
```

Or all stages: `make docker_test_integration`

## Cloud Build

Create a trigger on `build/int.cloudbuild.yaml` and set `_ORG_ID`, `_PROJECT_ID`, `_PROJECT_NUMBER`, `_DNS_ZONE_DOMAIN`, `_PLATFORM_ADMIN_MEMBERS`, plus either `_MCP_SSL_CERTIFICATE_ID` (A) or `_DNS_ZONE_NAME` (B).

`verify` asserts Terraform outputs, that the VPC and Agent Gateway exist, and that the attached cert is `ACTIVE`. It then builds the real MCP images, deploys the ADK `mortgage-agent` runtime, and sends the Playground prompts (Sterling tax/income summary, then email to `jane@example.com` with IAP in `DRY_RUN`). SSNs from the mock DMS must not appear in the replies. The reasoning engine is deleted at the end of `verify`.
