#!/usr/bin/env bash
# Creates the pull-through cache and the kind cluster. Safe to run twice.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
. "$here/../versions.env"

cache=zot-cache
volume=zot-cache-data
mirrors="docker.io=https://registry-1.docker.io ghcr.io=https://ghcr.io"

start_cache() {
  if [ -z "$(docker ps -aq -f "name=^${cache}$")" ]; then
    docker run -d --name "$cache" --restart unless-stopped \
      -p 127.0.0.1:5001:5000 \
      -v "$volume":/var/lib/zot \
      -v "$here/zot.json":/etc/zot/config.json:ro \
      "$ZOT_IMAGE" >/dev/null
  else
    docker start "$cache" >/dev/null
  fi
}

create_cluster() {
  if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "cluster $CLUSTER_NAME exists"
    return
  fi
  kind create cluster --name "$CLUSTER_NAME" --image "$KIND_NODE_IMAGE" \
    --config "$here/kind.yaml" --wait 120s
}

connect_cache() {
  docker network inspect kind --format '{{range .Containers}}{{.Name}} {{end}}' \
    | grep -qw "$cache" || docker network connect kind "$cache"
}

write_mirrors() {
  for node in $(kind get nodes --name "$CLUSTER_NAME"); do
    for entry in $mirrors; do
      host=${entry%%=*}
      upstream=${entry#*=}
      dir=/etc/containerd/certs.d/$host
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
