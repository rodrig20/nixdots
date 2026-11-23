#!/usr/bin/env bash
# cache-builder.sh — Build, filter, and upload a Nix binary cache to GHCR (OCI).
#
# Entry point only: shared defaults and info/err, then sources lib/cache/*.sh
# (one file per responsibility; the map lives in the README). Derived from
# cmspam/nixcache-oci @ 838bed6046ff2f0428b49485ebd07269cd0fc399 and split into
# files locally, so re-syncing means re-applying that split by hand.
#
# Design: each locally-built NAR becomes an OCI blob, each store path a tagged
# manifest, and a "cache-index" tag maps store hashes to those manifests.
# Upstream-available paths are never uploaded.
set -euo pipefail

# Repo root, derived from this file's location (used by every sourced part).
NIXCACHE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Shared defaults ────────────────────────────────────────────────────

: "${NIXCACHE_REPO:=cmspam/nixcache-oci}"
: "${NIXCACHE_REGISTRY:=ghcr.io}"
: "${NIXCACHE_SIGNING_KEY_FILE:=}"
: "${NIXCACHE_WORK_DIR:=$(mktemp -d)}"
: "${NIXCACHE_CONFIG_DIR:=config}"
: "${NIXCACHE_UPSTREAM_CACHES:=https://cache.nixos.org}"
: "${NIXCACHE_IMAGE:=${NIXCACHE_REGISTRY}/${NIXCACHE_REPO}/nix-cache}"

CACHE_DIR="${NIXCACHE_WORK_DIR}/cache"

info() { echo ">>> $*" >&2; }
err()  { echo "!!! $*" >&2; }

# ── Implementation ─────────────────────────────────────────────────────

source "$NIXCACHE_ROOT/lib/cache/oci.sh"
source "$NIXCACHE_ROOT/lib/cache/paths.sh"
source "$NIXCACHE_ROOT/lib/cache/export.sh"
source "$NIXCACHE_ROOT/lib/cache/index.sh"
source "$NIXCACHE_ROOT/lib/cache/substituter.sh"
source "$NIXCACHE_ROOT/lib/cache/pipeline.sh"
