# AGENTS.md — django-angular-boilerplate

This repo is a **consumer of ActionsCI/reusable-workflows**. It is also the
canonical smoke-test target that the reusable-workflows CI dispatches against
when validating changes to `build-eks.yaml`.

## Repo layout

```
.github/workflows/   CI/CD workflows (see .github/AGENTS.md)
.github/cicd.yaml    Single source of truth for pipeline config (see below)
helm/                Helm chart for EKS deployment
jely/                Django 2.1 backend (Python 3.7)
website/             Angular 5 frontend (Node 10 / Angular CLI 1.7)
Dockerfile           Multi-stage build: Angular → Django+gunicorn
```

## Tech stack

| Layer | Version | Notes |
|---|---|---|
| Backend | Django 2.1.3, DRF 3.9 | WSGI via gunicorn, port 3005 |
| Frontend | Angular 5, CLI 1.7.3 | `ng build --prod` → `website/dist/` |
| Runtime image | python:3.7-slim | `NODE_ENV` must not be set before `npm ci` |
| Container port | 3005 | Health probe: `/api/v1/health` |

## .github/cicd.yaml — schema

Read by `actionsci/reusable-workflows/.github/workflows/pre-build.yaml`.
Top-level key is `config:` (not `cicd:`). Each service is its own top-level
key sibling of `config:` — pre-build enumerates everything that isn't `config`.

| Field | Current value | Purpose |
|---|---|---|
| `config.version.major/minor` | `0` / `1` | Semver base |
| `config.version.release_branch` | `main` | Production deploys only on this branch |
| `config.deploy.environments.sandbox` | `true` | Required — PR smoke uses `env: sandbox` |
| `config.deploy.environments.production` | `true` | Key is `production`, not `prod` |
| `config.helm.chart_path` | `helm/` | |
| `config.helm.release_name` | `django-angular-boilerplate` | |
| `config.aws.ecr_url` | `01234567890.dkr.ecr.us-west-1.amazonaws.com` | |
| `config.aws.ecr_region` | `us-west-1` | |
| `django-angular-boilerplate.repository_name` | `django-angular-boilerplate` | ECR repo name |
| `django-angular-boilerplate.docker.dockerfile` | `Dockerfile` | |
| `django-angular-boilerplate.docker.context` | `.` | |

## Golden rules

1. **Never set `NODE_ENV` before `npm ci`** in the Dockerfile — npm 6 (node:10-alpine)
   treats `NODE_ENV=production` as `--omit=dev`, dropping Angular CLI from devDependencies.
   Declare `ARG NODE_ENV` only after the `npm ci` step.
2. **`cicd.yaml` is the config source of truth** — do not hardcode values from it
   into workflows or the Dockerfile; the reusable pipeline reads it directly.
3. **`settings.py` is gitignored** — `jely/jely/settings.py.txt` is the committed
   template. The Dockerfile bootstraps `settings.py` from it at build time.
4. **Default branch is `main`** — the reusable-workflows poller dispatches with
   `ref: main`. Workflows must exist on `main` to be discoverable.
5. **Do not modify `.github/workflows/pr-smoke-build-eks.yaml` run-name format**
   without coordinating with the reusable-workflows poller. See `.github/AGENTS.md`.

## Escalation

Pause and request human review when:
- Changing `cicd.yaml` field names or structure
- Modifying the `run-name` in `pr-smoke-build-eks.yaml`
- Adding new AWS IAM requirements
- Updating base images in the Dockerfile (Python or Node version bumps affect the
  entire build chain)
