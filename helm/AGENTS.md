# AGENTS.md — helm/

Helm chart for deploying django-angular-boilerplate to EKS.

## Chart identity

| Field | Value |
|---|---|
| Chart name | `django-angular-boilerplate-helm` |
| Release name | `django-angular-boilerplate` (from `cicd.yaml`) |
| Chart path | `helm/` (from `cicd.yaml`) |
| API version | v2 |

## Key values (values.yaml)

| Key | Value | Notes |
|---|---|---|
| `service.ports.http` | `3005` | Must match `EXPOSE` and gunicorn bind in Dockerfile |
| `service.probes.readiness.path` | `/api/v1/health` | Django must serve this endpoint |
| `hpa.minReplicas` / `maxReplicas` | 2 / 8 | HPA enabled by default |
| `resources.requests` | 500m CPU / 500Mi mem | |
| `resources.limits` | 1000m CPU / 1000Mi mem | |

## Golden rules

1. **Port 3005 is the contract** — it is referenced in `values.yaml`, the
   Dockerfile `EXPOSE`, the gunicorn bind, and the health probe. Change all
   four together or not at all.
2. **`targetGroupBindings`** — `publicTargetGroup` and `internalTargetGroup`
   are intentionally blank; they are populated by the GitOps pipeline per
   environment. Do not hardcode ARNs here.
3. **`irsaRolePrefix`** is blank in the chart default; it is injected per
   environment by the deployment pipeline.
