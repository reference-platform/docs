# Bootstrap

Scripts that create the local cluster and install the platform on it. `make up`
runs them in this order. All of them can run again on an existing cluster.

Requirements: Docker, kind, kubectl, Helm, jq and yq. `make preflight` checks them.

| File | What it does |
|---|---|
| `cluster.sh` | Starts the Zot pull-through cache, creates the kind cluster and points containerd on every node at the cache |
| `argocd.sh` | Installs ArgoCD with Helm, using the chart version and values from the gitops repo, and applies the root application |
| `wait.sh` | Waits until every ArgoCD application is Synced and Healthy. Fails after 15 minutes. |
| `kind.yaml` | Cluster layout: one control plane and two workers |
| `zot.json` | Base configuration of the cache |
| `registries.json` | Registries the cache mirrors |

Versions and names are set in `../versions.env`.

## Registry cache

The cache runs as a container next to the cluster, not inside it. It keeps its
images in a Docker volume, so a deleted cluster does not lose them. `make down`
stops the cache and keeps the volume. `make clean` removes both. See
[ADR 1](../../adr/0001-registry-cache.md).

Each node pulls through the cache with a `hosts.toml` file per registry. If the
cache has an image, it serves it. Otherwise it pulls from the upstream registry
and keeps a copy.

## ArgoCD

ArgoCD is installed once with Helm. The chart version and the values come from
`envs/dev/platform/argocd/` in the gitops repo. ArgoCD then reads the gitops
repo through the root application, which creates the projects, the namespaces
and the ApplicationSets. One of them deploys ArgoCD from the same folder, so
ArgoCD updates itself from Git. Running `argocd.sh` again re-applies the
version in Git and is the way to recover if ArgoCD breaks itself. Open the UI with `make forward` at `https://localhost:8080`.
The initial admin password is in the secret `argocd-initial-admin-secret`:

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```
