# Sealed secrets

Only `SealedSecret` YAML goes in this folder. It is encrypted with your cluster's public key,
so it is safe to commit. Generate the files in Lab 09:

| File | Secret it becomes | Used by |
| --- | --- | --- |
| `grafana-admin.yaml` | `monitoring/grafana-admin` (`admin-user`, `admin-password`) | Grafana login |
| `slack-webhook.yaml` | `monitoring/slack-webhook` (`url`) | Alertmanager Slack receiver |

The private key lives only in the cluster and in `~/.devops-proto/sealed-secrets-key.yaml`
(written by `make down`). Lose both and you must re-seal every secret.
