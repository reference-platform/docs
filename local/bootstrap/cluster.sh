#!/usr/bin/env bash
# Creates the pull-through cache and the kind cluster. Safe to run multiple times.

set -euo pipefail

cache=zot-cache
registries=bootstrap/registries.json
generated=$PWD/bootstrap/.generated

start_cache() {
  mkdir -p "$generated"
  jq --slurpfile list "$registries" '
    .extensions.sync.registries = [$list[0][] | {
      urls: [.upstream],
      onDemand: true,
      tlsVerify: true,
      content: [{ prefix: "**", destination: ("/" + .host) }]
    }]' bootstrap/zot.json >"$generated/config.json"
  docker rm -f "$cache" >/dev/null 2>&1 || true
  docker run -d --name "$cache" --restart unless-stopped \
    -p 127.0.0.1:5001:5000 \
    -v zot-cache-data:/var/lib/zot \
    -v "$generated":/etc/zot:ro \
    "$ZOT_IMAGE" >/dev/null
}

create_cluster() {
  if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "cluster $CLUSTER_NAME exists"
    return
  fi
  kind create cluster --name "$CLUSTER_NAME" --image "$KIND_NODE_IMAGE" \
    --config bootstrap/kind.yaml --wait 120s
}

connect_cache() {
  docker network inspect kind --format '{{range .Containers}}{{.Name}} {{end}}' \
    | grep -qw "$cache" || docker network connect kind "$cache"
}

write_mirrors() {
  nodes=$(kind get nodes --name "$CLUSTER_NAME")
  jq -r '.[] | "\(.host) \(.upstream)"' "$registries" | while read -r host upstream; do
    dir=/etc/containerd/certs.d/$host
    for node in $nodes; do
      docker exec -i "$node" sh -c "mkdir -p $dir && cat > $dir/hosts.toml" <<TOML
server = "$upstream"

[host."http://$cache:5000/v2/$host"]
  capabilities = ["pull", "resolve"]
  override_path = true
TOML
    done
  done
}

start_cache
create_cluster
connect_cache
write_mirrors
kubectl --context "kind-$CLUSTER_NAME" wait --for=condition=Ready nodes --all --timeout=120s
