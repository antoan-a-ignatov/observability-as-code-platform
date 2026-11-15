# Observability as Code Platform

## Project Status

**Current Version:** pre-release, no version tagged yet

**Status:** Milestone 1 (toolchain and repository setup) in progress. The first tagged version, v0.1.0, comes with the MVP at the end of Milestone 2.

## Introduction

A monitoring platform for a hybrid estate of Linux servers, a Kubernetes cluster and a Windows server, built, deployed and run entirely as code.

The scenario is a company partway through modernizing its infrastructure. A legacy Linux server runs PostgreSQL and nginx, an orders API runs on Kubernetes (k3s) and stores its data in that PostgreSQL, and a Windows back-office server runs a nightly PowerShell job that pulls orders from the API. One central team monitors all of it.

Terraform builds the infrastructure on AWS, Ansible configures every machine, and a CI/CD pipeline validates, scans and deploys every change. Naemon and Prometheus monitor the fleet, Grafana shows both, and Cribl filters logs before they reach Splunk, which is licensed by data volume.

## Table of Contents

1. [Skills Demonstrated](#skills-demonstrated)
2. [Architecture](#architecture)
3. [Demo](#demo)
4. [Repository Structure](#repository-structure)
5. [Technology Stack and Toolchain](#technology-stack-and-toolchain)
6. [Getting Started](#getting-started)
7. [CI/CD Pipeline](#cicd-pipeline)
8. [Monitoring](#monitoring)
9. [Logging](#logging)
10. [Security](#security)
11. [Engineering Challenges and Design Decisions](#engineering-challenges-and-design-decisions)
12. [Planned Improvements](#planned-improvements)
13. [AI Diligence Statement](#ai-diligence-statement)

## Skills Demonstrated

Filled in as each milestone is completed.

## Architecture

Added in Milestone 2, with the first deployed machines.

## Demo

Added in Milestone 7.

## Repository Structure

```
.
├── .github/
│   └── dependabot.yml                  Monthly version updates for the pre-commit hooks
├── scripts/
│   ├── milestones/                     Milestone and issue definitions, one JSON file per milestone
│   └── New-GitHubMilestoneIssues.ps1   Creates GitHub milestones and issues from those files
├── .gitignore
├── .pre-commit-config.yaml             Formatting, linting and secret scanning on every commit
├── LICENSE
└── README.md
```

## Technology Stack and Toolchain

### Stack

| Area | Tool |
|---|---|
| Cloud | AWS: EC2, S3, ECR, IAM, Systems Manager |
| IaC | Terraform |
| Configuration management | Ansible |
| Monitoring | Naemon, Prometheus, Alertmanager, Grafana, windows_exporter, NSClient++ |
| Logs | Splunk |
| Log pipeline | Cribl Stream |
| Log agent | Fluent Bit |
| Platform | k3s, Helm |
| Web server (Windows) | IIS |
| CI/CD | Atlassian Bamboo |
| Version control | Git, GitHub |
| Dependency updates | Dependabot |
| Secrets | HashiCorp Vault |
| Security scanning | Trivy, Snyk, Gitleaks |
| Scripting | PowerShell 7, Bash |
| OS | Ubuntu Server 24.04, Windows Server 2022 |

### Toolchain

Every tool on the workstation is pinned to a version. Downloads are verified against published checksums or signatures, and apt-installed tools are held so routine upgrades can't change them.

| Tool | Version |
|---|---|
| Terraform | 1.17.2 |
| tflint | 0.66.0 |
| AWS CLI | 2.40.1 |
| Session Manager plugin | 1.2.896.0 |
| ansible-core | 2.21.6 |
| ansible-lint | 26.11.0 |
| yamllint | 1.38.0 |
| pre-commit | 4.7.0 |
| kubectl | 1.37.1 |
| Helm | 4.3.1 |
| PowerShell | 7.6.10 (LTS) |
| Vault CLI | 2.2.1 |
| Trivy | 0.76.2 |
| Gitleaks | 8.30.1 |
| Snyk CLI | 1.1308.4 |

## Getting Started

Added in Milestone 2, together with the first full build from code.

## CI/CD Pipeline

Added in Milestone 2.

## Monitoring

Added in Milestone 2.

## Logging

Added in Milestone 3.

## Security

These rules apply from the first machine onward:

- No SSH or RDP. Machines and web UIs are reached only through AWS Systems Manager Session Manager and its port forwarding.
- No inbound traffic from the internet, except GitHub's webhook IP ranges into the CI server. Traffic between machines is opened per port, and only from the security group that needs it.
- IAM roles scoped to each machine and to CI. No long-lived AWS access keys.
- IMDSv2 required, EBS volumes encrypted, automatic security updates.
- No plaintext secrets in the repository. Until Vault arrives in Milestone 6, secrets are generated on the machine that uses them and never committed.
- Gitleaks scans every commit before it leaves the workstation.

## Engineering Challenges and Design Decisions

**Dependabot over Renovate.** Renovate was the first choice for version updates, but its hosted GitHub app requires a separate Mend account and grants a third-party service write access to the repository. Dependabot is built into GitHub and needs only a config file. The trade-off: Dependabot understands standard formats such as `.pre-commit-config.yaml`, Terraform providers, Dockerfiles and Helm charts, while versions pinned in this project's own Ansible variables and scripts are updated by hand.

**Issue tracking generated from JSON.** Milestones and issues are defined in one JSON file per milestone and created by a PowerShell script. Each issue carries a fixed key, stored in its body as a hidden HTML comment, and the script matches on that key. Titles can repeat across milestones and can be edited on GitHub without the script creating duplicates, so the script is safe to run again.

**ansible-core 2.21, not 2.22.** ansible-core 2.22 requires Python 3.13, while Ubuntu 24.04 ships Python 3.12. Staying on the 2.21 line avoids installing a second Python just for Ansible.

## Planned Improvements

- **Self-service onboarding:** one YAML file per service generates its Naemon checks, Prometheus rules, a Grafana dashboard and a Cribl route to its own Splunk index, so a team can add monitoring through a pull request. A Rundeck job to trigger onboarding is optional.

## AI Diligence Statement

This project was developed with the assistance of large language models as engineering tools. They were used to augment learning, planning, execution and problem solving, while all architectural decisions, implementation choices and final responsibility remain with me.
