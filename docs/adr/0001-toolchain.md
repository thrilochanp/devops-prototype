# ADR-0001: $0 local-first toolchain

- Status: accepted
- Date: 2026-10-23

## Context

The prototype must cover planning, IaC, CI/CD, configuration management, monitoring, security
and continuous improvement for $0/month, on one laptop, and move to Azure later without rework.

## Decision

| Area | Choice | Rejected alternative and why |
| --- | --- | --- |
| Workstation | macOS + Homebrew + Docker Desktop | Already installed and free for personal use (personal Mac). Colima: free, but one more tool to run; OrbStack: paid for commercial use |
| Kubernetes | kind | minikube: single node by default; k3d: fine, but kind is closer to upstream |
| IaC | Terraform | Pulumi: another language runtime to learn for no gain here |
| Config | Ansible + Helm | Kustomize alone: no packaging or templated values per env |
| CI | GitHub Actions (public repo) | Jenkins: always-on JVM, plugin maintenance |
| CD | Argo CD | Flux: no bundled UI for a learning prototype |
| Entry | Envoy Gateway (Gateway API) | Ingress NGINX: retired March 2026 |
| Logs | Loki + Grafana Alloy | Promtail: end of life March 2, 2026; ELK: too heavy for a laptop |
| Secrets | Sealed Secrets | Vault: a stateful server to run and unseal |
| Policy | Kyverno | OPA Gatekeeper: Rego learning curve |

## Consequences

- CI publishes multi-arch images (amd64 + arm64): Apple Silicon kind nodes are arm64, AKS nodes amd64.
- Repo must stay public to keep Actions and GHCR free.
- The Sealed Secrets key must be backed up outside Git before every `make down`.
- Every third-party GitHub Action is pinned to a commit SHA (Trivy tag hijack, March 2026).
- Workstation tools come only from homebrew-core (attestation-verified) and HashiCorp's official tap; Trivy is pinned and checksum-verified; pinning actions uses `gh api`, not a third-party tool.
