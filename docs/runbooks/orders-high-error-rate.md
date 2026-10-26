# Runbook: OrdersHighErrorRate

**Fires when** more than 5% of orders-api requests return 5xx for 2 minutes (critical).
**User impact** order creation and lookups fail for that share of requests.

## 1. Triage (first 5 minutes)

1. Acknowledge in `#alerts` with a thread reply: who is on it.
2. Which namespace? The alert title carries it (`orders-dev` or `orders-prod`).
3. Did something just change?
   ```bash
   argocd app history orders-prod | tail -3
   git log --oneline -5 -- deploy/envs/
   ```

## 2. Diagnose

- Error shape in Grafana Explore (Loki):
  `{namespace="orders-prod"} | json | status >= 500`
- Rate by route in Prometheus:
  `sum by (route, status) (rate(http_requests_total{namespace="orders-prod",status=~"5.."}[5m]))`
- Pod health: `kubectl -n orders-prod get pods` and `kubectl -n orders-prod describe pod <name>`

## 3. Mitigate

| Cause | Action |
| --- | --- |
| Bad release | Revert the tag change: `git revert <sha>` via PR, then `argocd app sync orders-prod` |
| Chaos left on (dev only) | `curl -X POST http://orders-dev.localtest.me:8080/chaos -H 'content-type: application/json' -d '{"error_rate":0}'` |
| Pod crash-looping | Check limits / OOMKilled in `describe`; raise memory limit in values via PR |

## 4. Close out

- Confirm the resolved message in `#alerts`.
- Record detection time, mitigation time and cause in the incident issue.
- One follow-up action, written as an ADR or an issue, in the next retro.
