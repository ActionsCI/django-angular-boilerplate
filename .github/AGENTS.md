# AGENTS.md — .github/

This directory contains the CI/CD workflows for django-angular-boilerplate.
Read this before touching any workflow file.

## Workflow inventory

### `pr-docker-build.yaml`
**Trigger:** every pull_request  
**Purpose:** verify the Dockerfile builds cleanly on every PR, no registry
credentials required.  
**Implementation:** calls `ActionsCI/docker-build-push@main` composite action
with `push: false` — builds locally, image is never pushed.  
**Inputs used:** `service_name`, `image_tag` (pr-{number}-{sha}),
`registry_url` (tag-only, not contacted), `build_args: NODE_ENV=production`.

### `pr-smoke-build-eks.yaml`
**Trigger:** `workflow_dispatch` only — dispatched by
`actionsci/reusable-workflows/.github/workflows/build-eks-pr-test.yaml`  
**Purpose:** smoke-test changes to `build-eks.yaml` in the reusable-workflows
repo before they merge. This workflow is a **passive dispatch target**; it is
not triggered by PRs to this repo.

**CRITICAL — run-name contract:**
```
"PR #${{ inputs.pr_number }} build-eks smoke (caller ${{ inputs.caller_run_id }})"
```
The poller in reusable-workflows locates this run by substring-matching
`display_title` for `"caller <caller_run_id>"`. **Do not change this format**
without updating the poller in reusable-workflows simultaneously.

**CRITICAL — `uses:` ref is the literal branch `@pr-smoke`:**
GitHub does not allow any expression in a reusable workflow's `uses:` ref —
not `inputs.*`, not `github.event.inputs.*`. The workaround: the
reusable-workflows PR-test job force-updates `refs/heads/pr-smoke` to the
PR's head SHA immediately before dispatching this workflow. `@pr-smoke` is
therefore always "the SHA under test". Concurrency in the dispatching job
serializes smokes so two PRs don't race over the same branch.

**Do not replace `@pr-smoke` with an expression** — it will silently resolve
to empty or fail to parse.

`reusable_workflows_ref` has been removed as an input; it is no longer needed.

**Inputs:**
| Input | Purpose |
|---|---|
| `reusable_workflows_ref` | SHA of reusable-workflows to call (e.g. the PR's head SHA) |
| `pr_number` | PR number in reusable-workflows (for run-name and target_branch) |
| `caller_run_id` | Parent run ID used by the poller to find this run |

**What it does:** calls `build-eks.yaml@{reusable_workflows_ref}` with
`env: sandbox`, `ref: main`, `target_branch: pr-test/{pr_number}`.

## Relationship to actionsci/reusable-workflows

| Concern | Lives in |
|---|---|
| Docker build check (PR gate) | This repo — `pr-docker-build.yaml` |
| Full build-eks smoke test | Dispatched from reusable-workflows to `pr-smoke-build-eks.yaml` here |
| `build-eks.yaml` logic | reusable-workflows |
| `pre-build.yaml`, `service-deployment-gitops.yaml` | reusable-workflows |
| `docker-build-push` composite action | ActionsCI/docker-build-push |

## Secrets and environments

| Secret | Scope | Required by |
|---|---|---|
| `ACTIONS_CI_GITHUB_TOKEN` | Repo | `build-eks.yaml` — ECR login, gitops push |

The `sandbox` GitHub Environment is referenced by `service-deployment-gitops.yaml`
via `environment: ${{ inputs.env }}`. GitHub auto-creates it on first use;
pre-create it only if you need protection rules or environment-scoped secrets.

## Adding a new workflow

1. Check reusable-workflows first — the workflow may already exist.
2. If calling a reusable workflow, pin to `@main` unless smoke-testing a specific
   SHA (the smoke workflow uses `@${{ inputs.reusable_workflows_ref }}`).
3. For any workflow that pushes to ECR or gitops, it needs `ACTIONS_CI_GITHUB_TOKEN`.
4. For build-only PR checks, use `ActionsCI/docker-build-push@main` with `push: false`
   — no credentials needed.
