# 3. How the GitOps repo and the Argo CD Applications are organised

Status: accepted

## Context

The cluster is managed by Argo CD from one repo. The repo holds three kinds of
things:

- Platform components: third party Helm charts (Argo CD, Prometheus, Loki and
  more), each with its own settings and sometimes extra plain manifests.
- Apps: services that share one chart and differ only in their values.
- Plain manifests of an app, such as the database.

The layout must stay clear when the number of components, apps and environments
grows. Some platform components need their own sync settings. Argo CD itself is
one of the components.

Facts that shape the choice:

- Argo CD runs once per cluster. Each environment is one cluster.
- Platform components are few and different from each other. Apps are many and
  alike.
- A platform change should reach `prod` only after it ran in `dev`, so versions
  are pinned per environment.
- Sync waves work between Applications of an app of apps. They do not order the
  Applications that an ApplicationSet generates.
- Dependabot does not read Argo CD Application files. Renovate does.

Priorities, in order: ease of use for platform engineers and developers,
simplicity of the solution, then avoiding repeated files. Repeated files are
acceptable because a check can compare the environments.

## Options

1. App of apps with one explicit `Application` file per platform component.
   Easy to read, has per-component settings and sync waves. Each file repeats
   about 25 lines.
2. ApplicationSet with a small `config.yaml` per component. No repeated
   boilerplate. One template for all, no sync waves, and a homemade file format.
3. Wrapper chart per component (a local chart that depends on the upstream
   chart, with its own `templates/`), deployed by one ApplicationSet. One source
   per Application and Dependabot support. Values are nested under the
   dependency name, a lock file must be kept, no sync waves, and the bootstrap
   has to unnest the values.
4. A Helm chart that renders the `Application` objects from a list of
   components. Policy is written once, per-component entries are short, waves
   work, and environments can layer lists. It adds a template and a values
   schema that someone has to learn.
5. Kustomize with `helmCharts`. One source type. It needs a Kustomize build
   option in Argo CD and is less common for platform charts.

## Decision

Layout: component first. Each platform component and each app service has its
own folder, flat. Inside it, shared files sit next to one folder per cluster
(platform) or per environment (apps). The Argo CD configurations of a cluster are part of
the Argo CD component.

```
platform/<component>/  values.yaml, manifests/, <cluster>/{application.yaml, values.yaml}
apps/<service>/        values.yaml, <env>/values.yaml, manifests/
```

The folder `platform/argocd/<cluster>/` also holds `root.yaml`, `projects.yaml`,
`namespaces.yaml` and `appsets.yaml`.

Platform folders are named after the cluster, because a component runs once per
cluster. App folders are named after the environment. They are the same today.

- Helm reads the shared `values.yaml` first and the environment file after it.
  A missing file is skipped.
- A folder for a cluster or environment means the component or service runs
  there.
- One Argo CD per cluster. Versions are pinned per environment.

Platform (option 1):

- The root Application of a cluster is an app of apps. It has two sources: the
  wiring files in `platform/argocd/<cluster>/`, and every
  `platform/<component>/<cluster>/application.yaml`.
- Each component is one explicit Application with three sources: the upstream
  chart at a pinned version, the values files from this repo, and an optional
  `manifests/` folder in this repo.

Apps:

- Two ApplicationSets read the folders: `apps` (one Application per service,
  rendered with `charts/service` and the shared and environment values) and
  `apps-manifests` (plain manifests of an app).

Argo CD itself:

- Argo CD is a platform component. The bootstrap script installs it once from
  the values files that its `application.yaml` lists, then Argo CD updates
  itself from Git.
- Its Application does not prune. No Application has a finalizer, so deleting
  one never removes its workloads. The root Application and the `apps`
  namespace are marked so they are never pruned or deleted.

Why component first, not environment first:

- Services and charts have their own versions and move one at a time, which
  favours a folder per service.
- Adding a service or component happens more often than adding an environment.
- The shared file and the environment file sit next to each other, so the split
  between common and per-environment config is visible, and promotion and drift
  are a comparison of neighbouring files.
- An environment first layout makes a separate prod repo and a new environment
  easier, and "what runs in prod" one listing.

## Consequences

- Each platform Application is visible in one file. Settings such as server-side
  apply, no pruning or an extra source are set per component.
- Sync waves can be set on the Applications.
- A policy change touches every `application.yaml`. With more components or
  environments this gets costly, and the copies can drift.
- The bootstrap reads the Argo CD version and the list of values files from the
  Application file with `yq`.
- Renovate is needed for automated chart bumps. Dependabot does not read the
  Application files.
- Adding an app service is one values file. Adding a platform component is one
  folder.
- A change to a shared file reaches every environment in one merge. Only config
  that is not expected to change belongs there. Versions and image tags stay
  per environment. To roll out a change to one environment first, need to copy the
  current value into the other environments, then change the shared file.
- Creating an environment means adding files to each component that should run
  there.

## Revisit when

- There are more than about 15 platform components.
- More than two environments are live.
- The same policy change was made in three or more `application.yaml` files,
  twice.
- Ordering between components causes failures that waves cannot solve.
