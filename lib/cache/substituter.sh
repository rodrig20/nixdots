# Run proxy/main.py on the CI runner so previous uploads are reused, not rebuilt.

# ── Self-substituter ──────────────────────────────────────────────────

# start_self_substituter — start the proxy on the CI runner so Nix can pull
# previously-cached paths from our own GHCR cache instead of rebuilding them.
start_self_substituter() {
    info "Starting self-substituter to reuse previously cached builds"

    # NIXCACHE_ROOT is set by lib/cache-builder.sh when it sources us.
    local proxy_script
    proxy_script="${NIXCACHE_ROOT}/proxy/main.py"
    if [[ ! -f "$proxy_script" ]]; then
        info "Proxy script not found at $proxy_script, skipping self-substitution"
        return 0
    fi

    # NIXCACHE_UPSTREAM="" — skip proxy's internal upstream fallback. Nix
    # already queries cache.nixos.org and the flake's other substituters
    # directly in parallel, so the proxy blocking on an upstream HTTP call
    # per miss just serializes what Nix would otherwise do concurrently.
    NIXCACHE_REPO="$NIXCACHE_REPO" \
    NIXCACHE_PORT=37515 \
    NIXCACHE_LISTEN=127.0.0.1 \
    NIXCACHE_UPSTREAM="" \
    GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}" \
        python3 "$proxy_script" &
    SELF_PROXY_PID=$!

    # Wait for it to be ready
    local ready=false
    for i in $(seq 1 15); do
        if curl -fs --max-time 2 http://127.0.0.1:37515/nix-cache-info >/dev/null 2>&1; then
            ready=true
            break
        fi
        sleep 1
    done

    if [[ "$ready" == "true" ]]; then
        info "Self-substituter running (pid=$SELF_PROXY_PID)"
        # Configure Nix to use our own cache during builds
        # Try system config first, fall back to user config
        local nix_conf="/etc/nix/nix.conf"
        if [[ ! -w "$nix_conf" ]] && [[ ! -w "$(dirname "$nix_conf")" ]]; then
            nix_conf="${HOME}/.config/nix/nix.conf"
            mkdir -p "$(dirname "$nix_conf")"
        fi
        cat >> "$nix_conf" <<EOF
extra-substituters = http://127.0.0.1:37515
extra-trusted-substituters = http://127.0.0.1:37515
EOF
        info "Added self-substituter to $nix_conf"

        # Trust our own signing key so Nix will accept signed NARs served
        # by the proxy. Without this, require-sigs rejects them and we'd
        # rebuild everything on every run instead of substituting.
        if [[ -n "${NIXCACHE_SIGNING_KEY_FILE:-}" ]] && [[ -f "$NIXCACHE_SIGNING_KEY_FILE" ]]; then
            local pub_key
            pub_key=$(nix key convert-secret-to-public < "$NIXCACHE_SIGNING_KEY_FILE" 2>/dev/null || true)
            if [[ -n "$pub_key" ]]; then
                echo "extra-trusted-public-keys = $pub_key" >> "$nix_conf"
                info "Trusted own public key: $pub_key"
            fi
        fi
    else
        info "Self-substituter failed to start, continuing without it"
        kill "$SELF_PROXY_PID" 2>/dev/null || true
        SELF_PROXY_PID=""
    fi
}
stop_self_substituter() {
    if [[ -n "${SELF_PROXY_PID:-}" ]]; then
        kill "$SELF_PROXY_PID" 2>/dev/null || true
        info "Self-substituter stopped"
    fi
}
