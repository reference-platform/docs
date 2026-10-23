Reference platform for Kubernetes. Built by Oleksandr Goltsman. Not production.

## What this is

A Kubernetes platform that runs fully on one laptop. I built it the way I build
platforms for real teams, after 13 years in DevOps and platform engineering.

It covers the full delivery path: GitOps with ArgoCD, canary releases gated by
SLOs, observability as code, policy as code, signed images, autoscaling, load
tests and failure drills.

No cloud account is needed.

This repo is the entry point. It holds the docs and the local startup scripts.

| Repo | What it holds |
|---|---|
| [docs](https://github.com/reference-platform/docs) | This repo. The README and the `local/` scripts |
| [gitops](https://github.com/reference-platform/gitops) | Kubernetes manifests, one folder per environment. ArgoCD reads it |
| [shop](https://github.com/reference-platform/shop) | A small demo app with 3 services. Its CI builds, signs and opens a PR in gitops |
| [infra](https://github.com/reference-platform/infra) | Terraform modules and tests |

## Architecture

TODO

## Quick start

TODO

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

TODO

## License

All rights reserved. See [LICENSE](LICENSE).
