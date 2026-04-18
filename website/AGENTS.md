# AGENTS.md — website/

Angular 5 frontend. Built with Angular CLI 1.7.3.

## Build

```sh
npm ci          # install all deps including devDependencies
npm run build   # ng build --prod → outputs to website/dist/
```

The `dist/` directory is copied into the Django image at `jely/static/dist/`
during the Docker build. It is gitignored.

## Key config

- **outDir:** `dist/` (relative to `website/`) — set in `.angular-cli.json`
- **Prod flag:** `ng build --prod` enables AOT, tree-shaking, minification
- **Node version:** 10 (node:10-alpine in Docker) — required for CLI 1.7.3 compatibility

## Golden rules

1. **`NODE_ENV` must not be set when running `npm ci`** — npm 6 treats
   `NODE_ENV=production` as `--omit=dev`, which drops `@angular/cli` from
   devDependencies and breaks the build. This is handled in the Dockerfile
   by declaring `ARG NODE_ENV` only after `npm ci`.
2. **Do not upgrade Angular CLI or Angular without also updating the Node base
   image** — CLI 1.7.x is pinned to Node 10. Upgrades require coordinated
   changes to `Dockerfile`, `package.json`, and `cicd.yaml` build_args.
3. **`package-lock.json` must stay committed** — `npm ci` requires it for
   reproducible builds in CI.
