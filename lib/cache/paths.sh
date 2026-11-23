# Discover and build flake outputs, then keep only locally-built (unsigned) paths.

# ── Nix helpers ───────────────────────────────────────────────────────

discover_outputs() {
    local flake_dir="$1"
    local system
    system=$(nix eval --raw --impure --expr 'builtins.currentSystem')
    info "Discovering flake outputs for $system in $flake_dir"

    local flake_ref="path:$(realpath "$flake_dir")"

    if [[ ! -f "$flake_dir/flake.lock" ]]; then
        info "Generating flake.lock for $flake_dir"
        nix flake update --flake "$flake_ref" 1>&2
    fi

    local refs=()

    local pkg_names
    pkg_names=$(nix eval "$flake_ref#packages.${system}" --apply 'attrs: builtins.concatStringsSep "\n" (builtins.attrNames attrs)' --raw 2>/dev/null) || true
    if [[ -n "$pkg_names" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && refs+=("${flake_ref}#packages.${system}.${name}")
        done <<< "$pkg_names"
    fi

    local nixos_names
    nixos_names=$(nix eval "$flake_ref#nixosConfigurations" --apply 'attrs: builtins.concatStringsSep "\n" (builtins.attrNames attrs)' --raw 2>/dev/null) || true
    if [[ -n "$nixos_names" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && refs+=("${flake_ref}#nixosConfigurations.${name}.config.system.build.toplevel")
        done <<< "$nixos_names"
    fi

    local shell_names
    shell_names=$(nix eval "$flake_ref#devShells.${system}" --apply 'attrs: builtins.concatStringsSep "\n" (builtins.attrNames attrs)' --raw 2>/dev/null) || true
    if [[ -n "$shell_names" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && refs+=("${flake_ref}#devShells.${system}.${name}")
        done <<< "$shell_names"
    fi

    if [[ ${#refs[@]} -eq 0 ]]; then
        err "No buildable outputs found for $system in $flake_dir"
        return 1
    fi

    printf '%s\n' "${refs[@]}"
}

build_outputs() {
    local refs=("$@")
    local all_paths=()
    for ref in "${refs[@]}"; do
        info "Building $ref"
        local json_file
        json_file=$(mktemp)
        nix build "$ref" --no-link --accept-flake-config --json > "$json_file" 2>&2 || {
            err "Failed to build $ref"
            rm -f "$json_file"
            return 1
        }
        local paths
        paths=$(grep -o '\[.*\]' "$json_file" | jq -r '.[].outputs | to_entries[].value' 2>/dev/null) || {
            err "JSON parse failed, falling back to nix path-info"
            paths=$(nix path-info "$ref" 2>/dev/null)
        }
        rm -f "$json_file"
        all_paths+=($paths)
    done
    printf '%s\n' "${all_paths[@]}"
}

get_closure() {
    nix-store --query --requisites "$@" | sort -u
}
# find_locally_built_paths — enumerate the full closure of the given output
# paths and return only those with NO signatures. Paths substituted from
# any cache (external or our own) carry that cache's signature in their
# narinfo; locally-built paths have no signature. Skip anything already in
# our GHCR index (uploaded in a previous run). This replaces the old
# --dry-run narinfo fan-out: it's pure local sqlite state, thousands of
# times faster, and it's what cachix-action does.
find_locally_built_paths() {
    local paths=("$@")

    # Pull our GHCR index so we can skip already-uploaded paths.
    local own_hashes=""
    oci_get_token 2>/dev/null || true
    local existing_manifest
    existing_manifest=$(oci_get_manifest "cache-index" 2>/dev/null)
    if [[ -n "$existing_manifest" ]]; then
        local index_digest
        index_digest=$(echo "$existing_manifest" | jq -r '.layers[0].digest // empty' 2>/dev/null)
        if [[ -n "$index_digest" ]]; then
            own_hashes=$(oci_get_blob "$index_digest" 2>/dev/null | \
                jq -r '.entries | keys[]' 2>/dev/null || true)
        fi
    fi
    local own_count=0
    if [[ -n "$own_hashes" ]]; then
        own_count=$(echo "$own_hashes" | wc -l)
    fi
    info "GHCR index contains $own_count previously-cached entries"

    # Walk the closure once. `nix path-info --json --recursive` returns
    # either a list (newer Nix) or a path-keyed object (older Nix); the
    # jq normalization handles both.
    nix path-info --json --recursive "${paths[@]}" 2>/dev/null | \
        jq -r '
            (if type == "array" then .
             else (to_entries | map({path: .key} + .value))
             end) |
            .[] | select((.signatures // []) | length == 0) | .path
        ' | while IFS= read -r path; do
            [[ -n "$path" ]] || continue
            local h
            h=$(basename "$path" | cut -c1-32)
            if [[ -n "$own_hashes" ]] && echo "$own_hashes" | grep -qxF "$h"; then
                continue
            fi
            echo "$path"
        done | sort -u
}
