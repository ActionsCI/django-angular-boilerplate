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

## Configuring for a new project

The pipeline is driven entirely by `.github/cicd.yaml`. The reusable-workflows
system reads it at build time, so **all project-specific values live in `cicd.yaml`,
not in the workflow files themselves**. Follow these steps when adopting this repo
as a template for a new service.

### 1 — Rename the service key

The top-level key `django-angular-boilerplate:` (line 27 of `cicd.yaml`) is the
**service name**. Replace it — and the matching `config.helm.release_name` — with
your service name. The key must equal the ECR repository name you create.

```yaml
# cicd.yaml — rename both occurrences
config:
  helm:
    release_name: <your-service-name>   # ← change this

<your-service-name>:                    # ← and this top-level key
  repository_name: <your-service-name>
```

### 2 — Set your AWS values

Replace the three placeholder values under `config.aws`:

| Field | What to set |
|---|---|
| `ecr_url` | `<account-id>.dkr.ecr.<region>.amazonaws.com` |
| `ecr_region` | AWS region of your ECR registry |
| `role_arn` | ARN of the IAM role GitHub Actions OIDC assumes for ECR push and EKS deploy |

The IAM role needs a trust policy allowing `token.actions.githubusercontent.com`
for this repository, plus permissions to push to ECR and write to the gitops repo.

### 3 — Configure environments

Set each entry under `config.deploy.environments` to `true` or `false` to match
the EKS namespaces you have provisioned. **`sandbox: true` must remain `true`** if
this repo is registered as a smoke-test target for actionsci/reusable-workflows
(the default for this boilerplate — see `.github/AGENTS.md`).

### 4 — Add the GitHub secret

Create a repository secret named **`ACTIONS_CI_GITHUB_TOKEN`** with a token that
has write access to the gitops repository consumed by
`service-deployment-gitops.yaml` in reusable-workflows. ECR login uses the OIDC
role from Step 2, not this token.

### 5 — Update the Helm chart

In `helm/Chart.yaml` set `name:` to match your service. In `helm/values.yaml`
update the image repository URL to your ECR. Port `3005` and the readiness probe
at `/api/v1/health` are defined in the Helm chart; change them there if your
service listens differently.

### Reusable workflows called by this repo

The `.github/workflows/` files are thin wrappers; all build logic lives in
actionsci/reusable-workflows. Do **not** change `uses:` refs without reading
`.github/AGENTS.md` first.

| Local workflow | Calls | Fixed ref |
|---|---|---|
| `pr-docker-build.yaml` | `ActionsCI/docker-build-push` composite action | `@main` |
| `pr-smoke-build-eks.yaml` | `actionsci/reusable-workflows/.github/workflows/build-eks.yaml` | `@pr-smoke` (literal — not an expression) |

`build-eks.yaml` internally calls `pre-build.yaml` and
`service-deployment-gitops.yaml` from the same reusable-workflows repo.
`pre-build.yaml` is the component that reads `.github/cicd.yaml` and drives the
build matrix.

### What NOT to change when adopting

- **`config:` top-level key name** — `pre-build.yaml` looks for it literally.
- **`@pr-smoke` ref** in `pr-smoke-build-eks.yaml` — GitHub forbids expressions in
  `uses:` refs; this literal branch is force-updated by the reusable-workflows
  dispatcher before each smoke run.
- **`run-name` format** in `pr-smoke-build-eks.yaml` — the poller finds this run
  by substring-matching the title; see `.github/AGENTS.md`.
- **`sandbox: true`** in `config.deploy.environments` — the smoke always calls with
  `env: sandbox`.
- **`NODE_ENV` placement in Dockerfile** — must come after `npm ci` (Golden rule §1).

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
