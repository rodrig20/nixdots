# Export store paths as compressed NARs + narinfo (text written by narinfo.py).

# export_paths_directly <store_paths...> — export only the given paths as NARs
# MUCH faster than `nix copy --to file://`: dump, compress, hash, narinfo, sign.
export_paths_directly() {
    local paths=("$@")
    if [[ ${#paths[@]} -eq 0 ]]; then
        info "No paths to export"
        return 0
    fi

    mkdir -p "$CACHE_DIR/nar"

    # Sign paths in the local store if we have a key
    if [[ -n "$NIXCACHE_SIGNING_KEY_FILE" ]]; then
        info "Signing ${#paths[@]} store paths"
        nix store sign --key-file "$NIXCACHE_SIGNING_KEY_FILE" "${paths[@]}" 2>&1 >&2 || true
    fi

    info "Exporting ${#paths[@]} store paths (direct NAR dump, skipping full closure)"

    for store_path in "${paths[@]}"; do
        local hash
        hash=$(basename "$store_path" | cut -c1-32)
        local nar_file="$CACHE_DIR/nar/${hash}.nar.xz"

        # Dump and compress the NAR
        nix-store --dump "$store_path" | xz -1 > "$nar_file"

        local file_size file_hash
        file_size=$(stat -c%s "$nar_file")
        file_hash=$(nix hash file --type sha256 --base32 "$nar_file")

        # Get path info for narinfo metadata
        local path_info
        path_info=$(nix path-info --json "$store_path" 2>/dev/null)

        # Generate narinfo (the writing logic lives in narinfo.py)
        python3 "$NIXCACHE_ROOT/lib/cache/narinfo.py" \
            "$store_path" "$hash" "$nar_file" "$file_size" "$file_hash" "$CACHE_DIR" "$path_info"

        info "  Exported $hash ($(numfmt --to=iec "$file_size" 2>/dev/null || echo "${file_size}B"))"
    done

    info "Export complete: ${#paths[@]} paths"
}
