# 2. How versions are chosen

Status: accepted

## Context

The platform uses many languages, images, charts and tools. Versions chosen by
habit or memory age quickly. A new release may also be too young to use, because
its dependencies and prebuilt packages lag behind.

## Options

1. Always the newest release. Fewest old versions. A `.0` release has early bugs and missing packages.
2. Newest stable release that has proven itself, checked against registries and support dates at the moment of pinning. Needs a lookup each time.
3. One release behind the newest (n-1). Safe, but often old without a reason.
4. Only long-term support releases. Stable. Many tools have none, and it lags for the rest.

## Decision

Option 2. Before a version is pinned, check it against live sources, not memory.

- **Patch:** the latest patch of the chosen minor. Pin it exactly.
- **Language runtimes:** the newest minor that
  - is inside its support window,
  - has at least one patch release (not a `.0`),
  - is supported by all key dependencies, and
  - passes the tests of the project.
- **Libraries:** the newest stable release, pinned exactly in applications.
  A pre-release is allowed only when no stable one exists.
- **Base images:** the current stable Debian, `slim` variant. Alpine only when
  every dependency has musl packages.
- **Databases:** the latest major that has had a few patch releases.
- **Kubernetes and platform tools:** the newest release that fits the
  compatibility limits of the other parts (kubectl within one minor of the
  cluster, versions supported by ArgoCD).
- **Tags, not digests.** Images are pinned by an exact version tag. Dependabot
  or Renovate bumps them.

How to check:

- Support windows and latest releases: `https://endoflife.date/api/<product>.json`
- Image tags that exist: the Docker Hub API
  (`https://hub.docker.com/v2/repositories/library/<image>/tags`) or
  `docker buildx imagetools inspect <image>:<tag>`
- Package versions: `pip index versions <package>`, `go list -m -versions <module>`,
  `helm search repo <chart> --versions`

## Consequences

- Each pin needs a short lookup. The result is a known, supported version.
- Pinned tags are mutable in theory. A digest would fix that, at the cost of
  more noise. Automated bumps keep the tags current.
- Versions are listed in `versions.env`, `requirements.txt`, Dockerfiles and
  `go.mod`, so they can be audited in one search.

## Revisit when

A tag is replaced under the same name and breaks a build, or the platform
adds image signing and policy that require digests.
