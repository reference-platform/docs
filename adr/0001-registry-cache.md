# 1. Pull-through registry cache outside the cluster

Status: accepted

## Context

A fresh cluster pulls many images from docker.io and ghcr.io. Cold starts are
slow and can hit rate limits. The platform is rebuilt often, so images should
be pulled from the internet once.

## Options

1. Zot as a container next to the cluster. Mirrors several registries on
   demand from one instance. Small and OCI native. Less known than Harbor.
2. `registry:2` in proxy mode. Very common. Mirrors only one upstream, so it
   needs one container per registry.
3. Harbor. Full feature set, with UI and scanning. Too heavy for a laptop.

## Decision

Zot, run as a plain container next to the cluster, not as a pod in it.
The kind nodes use it through containerd `hosts.toml` mirrors. Its data sits
in a Docker volume.

It runs outside the cluster because:

- containerd on the nodes pulls the images. The cache must exist before the
  first pull, including the images of the cluster itself. A cache pod would
  need an image pull to start, and no cache would exist yet.
- The cache must survive `make down`. A cache inside the cluster is deleted
  with it, so there would be no warm start.
- It needs no Kubernetes networking, storage or GitOps sync.

Only docker.io and ghcr.io are mirrored, because those are the registries in
use. Add a registry to `zot.json` and `cluster.sh` when an image needs it.

## Consequences

- Zot is a prerequisite of the platform, like the container runtime. It is not
  managed by ArgoCD.
- `make down` keeps the cache. `make clean` removes it.
- This matches production practice, where the pull-through cache is a registry
  service outside the cluster (for example Harbor or a cloud registry cache).

## Revisit when

The platform needs image scanning or access control on the cache. Harbor
becomes the better fit then.
