# devops-prototype

A $0, local-first DevOps platform: GitHub Actions CI, Argo CD GitOps, Envoy Gateway,
Prometheus/Grafana/Loki observability, Kyverno policy and Sealed Secrets on a kind cluster,
with a cloud-later path to Azure AKS.

## Layout

| Path | What lives there |
| --- | --- |
| `ansible/` | Workstation bootstrap playbook (macOS: Homebrew + Docker Desktop) |
| `app/` | `orders-api` FastAPI service, tests, Dockerfile |
| `infra/local/` | Terraform for the kind cluster |
| `infra/azure/` | Terraform for AKS Free tier + budget (Lab 13) |
| `platform/gateway/` | Gateway API resources for Envoy Gateway |
| `deploy/charts/orders-api/` | Helm chart for the app |
| `deploy/envs/{dev,prod}/` | Per-environment values (CI bumps dev) |
| `gitops/` | Argo CD app-of-apps, platform values, policies, sealed secrets |
| `scripts/` | `up`, `down`, Docker Desktop readiness, sealing-key backup/restore, DORA report |
| `docs/adr/` | Architecture decision records |

## Daily loop

```bash
make up      # create kind cluster, gateway, Argo CD, then GitOps restores everything
make down    # back up the sealing key, destroy the cluster ($0 when idle)
make down-vm # same, then quit Docker Desktop to give the RAM back to macOS
make doctor  # print tool versions and cluster health
```

Replace `thrilochanp` everywhere with your GitHub username in lowercase (Lab 02).
