# AGENTS.md — django-angular-boilerplate

This repo is a **consumer of ActionsCI/reusable-workflows**. It is also the
canonical smoke-test target that the reusable-workflows CI dispatches against
when validating changes to `build-eks.yaml`.

## Repo layout

```
.github/workflows/   CI/CD workflows (see .github/AGENTS.md)
helm/                Helm chart for EKS deployment
jely/                Django 2.1 backend (Python 3.7)
website/             Angular 5 frontend (Node 10 / Angular CLI 1.7)
cicd.yaml            Single source of truth for pipeline config
Dockerfile           Multi-stage build: Angular → Django+gunicorn
```

## Tech stack

| Layer | Version | Notes |
|---|---|---|
| Backend | Django 2.1.3, DRF 3.9 | WSGI via gunicorn, port 3005 |
| Frontend | Angular 5, CLI 1.7.3 | `ng build --prod` → `website/dist/` |
| Runtime image | python:3.7-slim | `NODE_ENV` must not be set before `npm ci` |
| Container port | 3005 | Health probe: `/api/v1/health` |

## cicd.yaml — key fields

`cicd.yaml` is read by `actionsci/reusable-workflows/.github/workflows/pre-build.yaml`
to drive the build pipeline. Do not rename top-level keys without checking
pre-build.yaml's parser.

| Field | Current value | Purpose |
|---|---|---|
| `cicd.service_name` | `django-angular-boilerplate` | Image name, release name |
| `cicd.docker.dockerfile` | `Dockerfile` | Path from repo root |
| `cicd.docker.context` | `.` | Build context |
| `cicd.docker.build_args.NODE_ENV` | `production` | Passed to Docker |
| `cicd.helm.chart_path` | `helm/` | Helm chart location |
| `cicd.helm.release_name` | `django-angular-boilerplate` | Helm release name |
| `cicd.aws.ecr_url` | `01234567890.dkr.ecr.us-west-1.amazonaws.com` | ECR registry |
| `cicd.aws.ecr_region` | `us-west-1` | AWS region |

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
