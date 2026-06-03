![Terraform](https://img.shields.io/badge/Terraform-1.9.8-7B42BC?logo=terraform) ![Azure](https://img.shields.io/badge/Azure-azurerm-0078D4?logo=microsoftazure) ![Pipeline](https://img.shields.io/badge/CI%2FCD-Azure%20DevOps-0078D4?logo=azuredevops) ![Checkov](https://img.shields.io/badge/Security-Checkov%20%7C%20Prisma%20Cloud-brightgreen) ![License](https://img.shields.io/badge/License-MIT-green)

# Azure High Availability Infrastructure Platform

> A production-ready, modular Terraform platform that provisions a scalable, secure, and highly available web application hosting environment on Microsoft Azure — built to demonstrate real-world cloud infrastructure and DevOps engineering practices.

This project provisions everything needed to run a high-traffic, fault-tolerant workload on Azure: networking, compute with auto-scaling, load balancing, observability, and secret management — all wired together with a fully automated, gated CI/CD pipeline.

---

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │            INTERNET                  │
                        └──────────────────┬──────────────────┘
                                           │
                        ┌──────────────────▼──────────────────┐
                        │         Azure Load Balancer          │
                        │    Public IP │ Health Probes         │
                        └──────────────────┬──────────────────┘
                                           │
                        ┌──────────────────▼──────────────────┐
                        │    Virtual Machine Scale Set         │
                        │    Ubuntu 22.04 LTS                  │
                        │    Min: N │ Max: N │ CPU Autoscale   │
                        └──────┬───────────────────┬──────────┘
                               │                   │
          ┌────────────────────▼───┐       ┌───────▼────────────────────┐
          │     Public Subnet      │       │      Private Subnet         │
          │  HTTP/HTTPS: open      │       │  Internal traffic only      │
          │  SSH: restricted CIDR  │       │  NSG protected              │
          └────────────────────────┘       └────────────────────────────┘
                               │
          ┌────────────────────┼───────────────────────┐
          │                    │                        │
┌─────────▼──────────┐ ┌───────▼──────────┐ ┌─────────▼──────────┐
│   Azure Key Vault   │ │  Log Analytics   │ │   Azure Monitor    │
│  Secrets at rest    │ │  Workspace       │ │   Alerts + Email   │
│  RBAC access only   │ │  Centralised     │ │   Notifications    │
└─────────────────────┘ └──────────────────┘ └────────────────────┘

─────────────────────────────────────────────────────────────────
State Backend: Azure Blob Storage
  dev/terraform.tfstate
  staging/terraform.tfstate
  prod/terraform.tfstate
─────────────────────────────────────────────────────────────────
```

---

## What This Platform Provides

| Capability | Detail |
|---|---|
| High Availability | VMSS with configurable min/max instances across fault domains |
| Auto Scaling | CPU-based scale out and scale in with configurable thresholds |
| Load Balancing | Azure Load Balancer with health probes and backend pool |
| Network Security | NSG-protected subnets, SSH restricted to allowed CIDRs |
| Secret Management | Azure Key Vault — no credentials in code or pipeline variables |
| Observability | Log Analytics Workspace + Azure Monitor alerts with email notifications |
| Multi-Environment | Independent dev / staging / prod configurations |
| Remote State | Azure Blob Storage with environment-scoped state files |

---

## Tech Stack

| Category | Tool / Service |
|---|---|
| Infrastructure as Code | Terraform 1.9.8 |
| Cloud Provider | Microsoft Azure (`azurerm`) |
| CI/CD | Azure DevOps Pipelines |
| Secret Management | Azure Key Vault |
| State Backend | Azure Blob Storage |
| Security Scanning | Checkov (Prisma Cloud) |
| Linting | TFLint |

---

## Repository Structure

```
poc-terraform/
├── azure-pipeline.yaml          # Azure DevOps multi-stage pipeline
└── ha-setup/
    ├── env/
    │   ├── dev/                 # Dev environment entry point
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── terraform.tfvars
    │   │   ├── provider.tf
    │   │   └── backend.tf
    │   ├── staging/             # Staging environment entry point
    │   └── prod/                # Production environment entry point
    └── modules/
        ├── rg/                  # Resource Group
        ├── network/             # VNet, public + private subnets
        ├── nsg/                 # Network Security Group rules
        ├── loadbalancer/        # Azure Load Balancer
        ├── vmss/                # Virtual Machine Scale Set
        ├── autoscale/           # Autoscale policies (CPU-based)
        ├── monitoring/          # Log Analytics Workspace
        ├── alerts/              # Azure Monitor alerts
        └── vm/                  # Standalone VM module
```

---

## CI/CD Pipeline

The pipeline is **manually triggered** and parameterised by environment (`dev`, `staging`, `prod`). Nothing reaches Apply without passing every gate — security scan, linting, format check, and human approval.

```
Run Pipeline → select environment (dev / staging / prod)
        │
        ▼
┌──────────────────────────────────────────────┐
│  VALIDATE                                    │
│  • terraform fmt -check (format enforcement) │
│  • terraform init + validate                 │
│  • TFLint (typed variables, best practices)  │
│  • Checkov security scan (Prisma Cloud)      │
└──────────────────────┬───────────────────────┘
                       │ all checks pass
                       ▼
┌──────────────────────────────────────────────┐
│  PLAN                                        │
│  • terraform plan -out=tfplan                │
│  • tfplan uploaded as pipeline artifact      │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│  APPROVAL                                    │
│  • Manual review gate (24hr window)          │
│  • Reviewer inspects plan before approving   │
│  • Auto-rejects on timeout                   │
└──────────────────────┬───────────────────────┘
                       │ approved
                       ▼
┌──────────────────────────────────────────────┐
│  APPLY                                       │
│  • Downloads tfplan artifact from Plan stage │
│  • terraform apply (executes exact plan)     │
└──────────────────────────────────────────────┘
```

### Pipeline Design Decisions

**Artifact-based plan promotion** — the `tfplan` binary is uploaded as a pipeline artifact after Plan and downloaded in Apply. This guarantees Apply executes exactly what was reviewed, even across fresh agents — no drift, no surprises.

**Manual approval gate** — Apply never runs automatically. A reviewer must inspect the plan output and explicitly approve. The gate auto-rejects after 24 hours to prevent stale approvals reaching production.

**Security scanning before cloud touches** — Checkov runs in the Validate stage before any Azure resources are touched. Known exceptions are explicitly skipped with inline documented reasons (`--skip-check`).

**TFLint with strict variable typing** — all variables are typed (`string`, `number`, `bool`) and validated by TFLint before plan runs, catching issues that `terraform validate` misses.

---

## Multi-Environment Configuration

Each environment has its own `terraform.tfvars` — fully independent, no shared state:

| Variable | Description |
|---|---|
| `environment` | Name tag applied to all resources |
| `location` | Azure region |
| `vnet_cidr` | VNet address space |
| `public_subnet_cidr` | Public subnet CIDR |
| `private_subnet_cidr` | Private subnet CIDR |
| `allowed_ssh_ip` | CIDR allowed for SSH access |
| `instance_count` | Initial VMSS instance count |
| `min_instance_count` | Autoscale floor |
| `max_instance_count` | Autoscale ceiling |
| `scale_out_cpu_threshold` | CPU % to trigger scale out |
| `scale_in_cpu_threshold` | CPU % to trigger scale in |
| `alert_email` | Email address for Monitor alerts |

---

## Security Posture

- SSH access restricted to specified CIDR — no open-world SSH rules
- NSG enforced on both public and private subnets — validated by Checkov `CKV2_AZURE_31`
- No credentials in code, pipeline variables, or state — all secrets via Azure Key Vault
- Service principal scoped with least-privilege `Key Vault Secrets User` RBAC role
- Security scan failures block the pipeline — Apply cannot run if Checkov fails

---

## Running Locally

Prerequisites: Terraform >= 1.9.8, Docker, Azure CLI authenticated

```bash
# Clone
git clone git@github.com:sureshanand1619/poc-terraform.git
cd poc-terraform

# Format check
terraform fmt -check -recursive ha-setup/

# Security scan
docker run --rm \
  -v $HOME/terraform/poc-terraform:/tf \
  bridgecrew/checkov \
  --directory /tf/ha-setup/

# Plan for dev
cd ha-setup/env/dev
terraform init
terraform plan
```

---

## About This Project

Built as a hands-on platform to demonstrate production-grade cloud infrastructure skills for a **DevOps / Cloud Engineer** role. Every design decision — modular Terraform, gated pipelines, Key Vault integration, NSG least-privilege rules — reflects patterns used in real enterprise Azure environments.