Reference platform for Kubernetes. Built by Oleksandr Goltsman. Not production.

## What this is

A Kubernetes platform that runs fully on one laptop. I built it the way I build
platforms for real teams, after 13 years in DevOps and platform engineering.

It shows GitOps with ArgoCD, a demo app with CI and multi-arch images, and a
local registry cache.

No cloud account is needed.

This repo is the entry point. It holds the docs and the local startup scripts.

| Repo | What it holds |
|---|---|
| [docs](https://github.com/reference-platform/docs) | This repo. The README and the `local/` scripts |
| [gitops](https://github.com/reference-platform/gitops) | Kubernetes manifests: platform components, apps and the Argo CD setup. ArgoCD reads it |
| [sample-app](https://github.com/reference-platform/sample-app) | A small demo app with 3 services. Its CI builds and publishes the images |

## Architecture

TODO

## Quick start

TODO

## Versions and timings

Versions are exact tags. See [ADR 2](adr/0002-version-policy.md) for the policy.

| Item | Version |
|---|---|
| kind | 0.33.0, node image `kindest/node:v1.37.0` |
| Zot (registry cache) | v2.1.22 |
| ArgoCD | Helm chart 10.11.6, app v3.5.6 |
| kube-prometheus-stack | Helm chart 92.20.0 (Prometheus Operator v0.94.2, Prometheus v3.15.1, Alertmanager v0.34.2, Grafana 13.3.0) |
| Loki | Helm chart 21.0.0 (Loki 3.7.9) |
| Alloy | Helm chart 1.15.0 (Alloy v1.21.3) |
| Helm (CI) | v4.3.1 |
| kubeconform (CI) | v0.8.0 |
| Python | 3.15.2 |
| Go | 1.27.3 |
| Postgres | 18.6 |
| dbmate | 2.37.0 |

Time for `make up` until all ArgoCD apps are Synced and Healthy, measured on an
Apple silicon laptop:

| Run | Time |
|---|---|
| Warm cache (cluster deleted, cache kept) | 2m17s |
| Cold cache | not measured |

## Demo script

TODO

## Decision table

TODO

## Trade-offs

TODO

## What changes in production

TODO

## Security notes

TODO

## How tests work

TODO

## Known gaps

TODO

## Next steps

TBD: canary releases gated by SLOs, observability as code, secrets and policy as
code, signed images, autoscaling, load tests, failure drills, an image build
that opens a pull request in gitops, and Terraform with tests that need no
cloud account.

## License

All rights reserved. See [LICENSE](LICENSE).
