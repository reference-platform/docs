#!/usr/bin/env bash

set -u

MIN_MEM_GB=16
MIN_DISK_GB=60
PORTS="80 443 3000 8080"

fails=0
warns=0
runtime_up=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; warns=$((warns + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }

check_arch() {
  arch=$(uname -m)
  if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    pass "CPU architecture: $arch"
  else
    warn "CPU architecture: $arch (this platform is built for arm64)"
  fi
}

check_runtime() {
  if ! command -v docker >/dev/null 2>&1; then
    fail "container runtime: docker CLI not found (brew install orbstack)"
    return
  fi
  if os=$(docker info --format '{{.OperatingSystem}}' 2>/dev/null); then
    runtime_up=1
    pass "container runtime is running: $os"
  else
    warn "container runtime is not running (start OrbStack or Docker Desktop)"
  fi
}

check_memory() {
  if [ "$runtime_up" -ne 1 ]; then
    warn "runtime memory: cannot check, the runtime is not running"
    return
  fi
  bytes=$(docker info --format '{{.MemTotal}}' 2>/dev/null)
  case "$bytes" in
    ''|*[!0-9]*) warn "runtime memory: cannot read the value"; return ;;
  esac
  gb=$((bytes / 1024 / 1024 / 1024))
  if [ "$gb" -ge "$MIN_MEM_GB" ]; then
    pass "runtime memory limit: ${gb} GB (need ${MIN_MEM_GB} GB)"
  else
    warn "runtime memory limit: ${gb} GB (want at least ${MIN_MEM_GB} GB)"
  fi
}

check_disk() {
  free_kb=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
  free_gb=$((free_kb / 1024 / 1024))
  if [ "$free_gb" -ge "$MIN_DISK_GB" ]; then
    pass "free disk: ${free_gb} GB (need ${MIN_DISK_GB} GB)"
  else
    fail "free disk: ${free_gb} GB (need at least ${MIN_DISK_GB} GB)"
  fi
}

# usage: check_tool <command> <fail|warn> <brew formula> <version command...>
check_tool() {
  cmd=$1; level=$2; formula=$3
  shift 3
  if ! command -v "$cmd" >/dev/null 2>&1; then
    msg="$cmd: not found (brew install $formula)"
    if [ "$level" = "fail" ]; then fail "$msg"; else warn "$msg"; fi
    return
  fi
  ver=$("$@" 2>&1 | head -n 1)
  pass "$cmd: $ver"
}

check_tools() {
  check_tool git       fail git                      git --version
  check_tool k6        fail k6                       k6 version
  check_tool kind      fail kind                     kind version
  check_tool kubectl   warn kubectl                  kubectl version --client
  check_tool helm      warn helm                     helm version --short
  check_tool jq        warn jq                       jq --version
  check_tool yq        warn yq                       yq --version
  check_tool terraform warn hashicorp/tap/terraform  terraform version
  check_tool tofu      warn opentofu                 tofu version
  check_tool tflint    warn tflint                   tflint --version
  check_tool trivy     warn trivy                    trivy --version
  check_tool conftest  warn conftest                 conftest --version
}

check_ports() {
  for p in $PORTS; do
    if nc -z 127.0.0.1 "$p" >/dev/null 2>&1; then
      fail "port $p: in use"
    else
      pass "port $p is free"
    fi
  done
}

check_arch
check_runtime
check_memory
check_disk
check_tools
check_ports

echo
if [ "$fails" -gt 0 ]; then
  echo "Result: $fails FAIL, $warns WARN. Fix the FAIL lines first."
  exit 1
fi
echo "Result: 0 FAIL, $warns WARN."
