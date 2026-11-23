# Orchestrate the cache steps in order and write the GitHub Actions summary.

full_pipeline() {
    local flake_dir="${NIXCACHE_CONFIG_DIR}"

    info "Starting OCI cache pipeline"
    info "Config: $flake_dir | Image: $NIXCACHE_IMAGE"

    # 0. Start our proxy as a substituter. Gives Nix access to paths
    #    cached from previous runs without rebuilding.
    SELF_PROXY_PID=""
    start_self_substituter

    # 1. Discover outputs.
    local discovered
    discovered=$(discover_outputs "$flake_dir")
    if [[ -z "$discovered" ]]; then
        err "No buildable outputs found in $flake_dir"
        stop_self_substituter
        return 1
    fi
    local refs_array
    mapfile -t refs_array <<< "$discovered"
    info "Discovered ${#refs_array[@]} output(s) to build"
    printf '    %s\n' "${refs_array[@]}" >&2

    # 2. Build all outputs. Nix does narinfo resolution and substitution
    #    inline, interleaved with compilation — no separate dry-run pass.
    #    --accept-flake-config so the flake's extra-substituters (jovian,
    #    cachyos via lantian, etc.) are used in parallel with cache.nixos.org.
    local output_paths
    output_paths=$(build_outputs "${refs_array[@]}")
    local paths_array
    mapfile -t paths_array <<< "$output_paths"
    info "Built ${#paths_array[@]} top-level output(s)"

    # Done with the self-substituter — the rest is local + GHCR uploads.
    stop_self_substituter

    # 3. Signature-based filter: upload only paths built locally (no sig).
    #    Paths with any signature came from some cache already.
    info "Inspecting closure signatures to find locally-built paths"
    local upload_list
    upload_list=$(find_locally_built_paths "${paths_array[@]}")
    if [[ -z "$upload_list" ]]; then
        info "Nothing to upload — every path has an external or existing signature"
        write_summary "${#refs_array[@]}" 0 0 "${#paths_array[@]}"
        return 0
    fi
    local upload_array
    mapfile -t upload_array <<< "$upload_list"
    info "Locally-built paths to upload: ${#upload_array[@]}"

    # 4. Export NARs (this step also signs them with our key).
    export_paths_directly "${upload_array[@]}"

    # 5. Upload NARs + index manifest to GHCR.
    upload_to_oci "${paths_array[@]}"

    write_summary "${#refs_array[@]}" "${#upload_array[@]}" "${#upload_array[@]}" "${#paths_array[@]}"
    info "Pipeline complete!"
}
# Write a GitHub Actions step summary if available
write_summary() {
    local outputs="$1" new_paths="$2" uploaded="$3" total_outputs="$4"
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        cat >> "$GITHUB_STEP_SUMMARY" <<EOF
## Cache Build Summary

| Metric | Count |
|---|---|
| Flake outputs discovered | $outputs |
| Output paths built | $total_outputs |
| New paths cached to GHCR | $new_paths |
| Paths already cached | skipped |
EOF
    fi
}
