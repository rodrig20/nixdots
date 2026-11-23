# Upload NARs to GHCR and merge the cache-index tag (JSON from merge-index.py).

# ── OCI upload pipeline ──────────────────────────────────────────────

# Upload all locally-built paths to GHCR as OCI artifacts. The existing index,
# per-path receipts, may grow past ARG_MAX: pass via files, not argv.
upload_to_oci() {
    info "Uploading to GHCR: ${NIXCACHE_IMAGE}"

    # Download existing index to a file.
    local existing_index_file="$NIXCACHE_WORK_DIR/existing-index.json"
    echo '{}' > "$existing_index_file"
    local existing_manifest
    existing_manifest=$(oci_get_manifest "cache-index")
    if [[ -n "$existing_manifest" ]]; then
        local index_digest
        index_digest=$(echo "$existing_manifest" | jq -r '.layers[0].digest // empty' 2>/dev/null)
        if [[ -n "$index_digest" ]]; then
            oci_get_blob "$index_digest" > "$existing_index_file" 2>/dev/null \
                || echo '{}' > "$existing_index_file"
        fi
    fi

    # Per-upload receipts go to a JSONL file.
    local receipts_file="$NIXCACHE_WORK_DIR/uploads.jsonl"
    : > "$receipts_file"

    local uploaded=0
    local upload_failures=0

    for narinfo in "$CACHE_DIR"/*.narinfo; do
        [[ -f "$narinfo" ]] || continue
        local hash
        hash=$(basename "$narinfo" .narinfo)

        local nar_url
        nar_url=$(grep '^URL: ' "$narinfo" | head -1 | cut -d' ' -f2)
        local nar_file="$CACHE_DIR/$nar_url"

        if [[ ! -f "$nar_file" ]]; then
            err "NAR file not found for $hash: $nar_url"
            continue
        fi

        local nar_size
        nar_size=$(stat -c%s "$nar_file")

        info "  Uploading NAR for $hash ($(numfmt --to=iec "$nar_size" 2>/dev/null || echo "${nar_size}B"))"
        local nar_digest
        nar_digest=$(oci_push_blob "$nar_file") || {
            err "Failed to upload NAR for $hash"
            upload_failures=$((upload_failures + 1))
            continue
        }

        # Append one-line JSON receipt; the final index-build reads these.
        jq -n -c \
            --arg hash "$hash" \
            --arg narinfo_file "$narinfo" \
            --arg nar_digest "$nar_digest" \
            --argjson nar_size "$nar_size" \
            '{hash: $hash, narinfo_file: $narinfo_file, nar_digest: $nar_digest, nar_size: $nar_size}' \
            >> "$receipts_file"

        uploaded=$((uploaded + 1))
    done

    if [[ "$uploaded" -eq 0 ]]; then
        info "No new paths to upload"
        return 0
    fi

    if [[ "$upload_failures" -gt 0 ]]; then
        err "$upload_failures upload(s) failed. Updating index with $uploaded successful upload(s) only."
    fi

    info "Uploaded $uploaded NAR(s), updating index"
    update_cache_index "$existing_index_file" "$receipts_file" "$@"
}

# Update the cache-index manifest with new entries.
# update_cache_index <existing_index_file> <receipts_file> <gc_root_paths...>
update_cache_index() {
    local existing_index_file="$1"
    local receipts_file="$2"
    shift 2
    local gc_root_paths=("$@")

    # Collect gc-root hashes into a file.
    local gc_roots_file="$NIXCACHE_WORK_DIR/gc-roots.json"
    local gc_json="[]"
    for p in "${gc_root_paths[@]}"; do
        local h
        h=$(basename "$p" | cut -c1-32)
        gc_json=$(echo "$gc_json" | jq -c --arg h "$h" '. + [$h]')
    done
    printf '%s' "$gc_json" > "$gc_roots_file"

    local public_key=""
    if [[ -n "$NIXCACHE_SIGNING_KEY_FILE" ]] && [[ -f "${NIXCACHE_SIGNING_KEY_FILE}.pub" ]]; then
        public_key=$(cat "${NIXCACHE_SIGNING_KEY_FILE}.pub")
    fi

    # Build the merged index in one Python run, reading large inputs from
    # files/env so argv stays tiny regardless of how many entries there are.
    local index_file="$NIXCACHE_WORK_DIR/cache-index.json"
    EXISTING_INDEX_FILE="$existing_index_file" \
    RECEIPTS_FILE="$receipts_file" \
    GC_ROOTS_FILE="$gc_roots_file" \
    OUTPUT_FILE="$index_file" \
    PUBLIC_KEY="$public_key" \
    NIXCACHE_REPO="$NIXCACHE_REPO" \
    NIXCACHE_REGISTRY="$NIXCACHE_REGISTRY" \
    NIXCACHE_IMAGE="$NIXCACHE_IMAGE" \
    GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    python3 "$NIXCACHE_ROOT/lib/cache/merge-index.py"

    # Push index as a blob
    local index_digest
    index_digest=$(oci_push_blob "$index_file")
    local index_size
    index_size=$(stat -c%s "$index_file")

    # Create an empty config blob (required by OCI spec)
    local config_file="$NIXCACHE_WORK_DIR/config.json"
    echo '{}' > "$config_file"
    local config_digest
    config_digest=$(oci_push_blob "$config_file")
    local config_size
    config_size=$(stat -c%s "$config_file")

    # Create and push the manifest tagged as cache-index
    local manifest
    manifest=$(jq -n \
        --arg config_digest "$config_digest" \
        --argjson config_size "$config_size" \
        --arg index_digest "$index_digest" \
        --argjson index_size "$index_size" \
        '{
            schemaVersion: 2,
            mediaType: "application/vnd.oci.image.manifest.v1+json",
            config: {
                mediaType: "application/vnd.oci.image.config.v1+json",
                digest: $config_digest,
                size: $config_size
            },
            layers: [{
                mediaType: "application/vnd.nix.cache.index.v1+json",
                digest: $index_digest,
                size: $index_size
            }]
        }')

    oci_push_manifest "cache-index" "$manifest"
    info "Cache index updated ($(echo "$new_entries" | jq 'length') new entries)"
}
