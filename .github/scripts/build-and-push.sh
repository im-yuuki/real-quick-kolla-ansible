#!/bin/bash
# Build + push Kolla images voi Ceph client moi hon len GHCR.
# Usage: build-and-push.sh REGISTRY_PREFIX BASE_TAG TARGET_TAG CEPH_RELEASE IMAGES...
# Vi du: build-and-push.sh ghcr.io/im-yuuki/real-quick-kolla-ansible \
#          2026.1-ubuntu-noble 2026.1-urban-noble-tentacle tentacle \
#          glance-api cinder-volume cinder-backup nova-compute nova-libvirt
set -euo pipefail

PREFIX="$1"
BASE_TAG="$2"
TARGET_TAG="$3"
CEPH_RELEASE="$4"
shift 4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${DOCKERFILE:-$SCRIPT_DIR/../../Dockerfile}"

for img in "$@"; do
  base="quay.io/openstack.kolla/${img}:${BASE_TAG}"
  out="${PREFIX}/${img}:${TARGET_TAG}"
  echo "=== building $img ==="
  docker pull "$base"
  base_user="$(docker inspect --format='{{.Config.User}}' "$base")"
  if [ -z "$base_user" ]; then
    base_user=root
  fi
  echo "base image: $base (user: $base_user)"
  docker build -f "$DOCKERFILE" \
    --build-arg "BASE_IMAGE=$base" \
    --build-arg "BASE_USER=$base_user" \
    --build-arg "CEPH_RELEASE=$CEPH_RELEASE" \
    -t "$out" \
    "$SCRIPT_DIR"
  echo "--- verify Ceph client in $out ---"
  ver="$(docker run --rm --entrypoint dpkg "$out" -l librados2 2>/dev/null | awk '/^ii/ {print $3}')"
  echo "librados2 version: $ver"
  case "$ver" in
    *20.2.0*) echo "ERROR: client still 20.2.0 (upgrade did not take effect)" >&2; exit 1;;
    *) echo "client version OK: $ver";;
  esac
  echo "--- push $out ---"
  docker push "$out"
done
echo "ALL_DONE"
