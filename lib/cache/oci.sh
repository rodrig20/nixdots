# GHCR/OCI registry API: token exchange, blob upload, manifest read/write.

# ── OCI registry helpers ──────────────────────────────────────────────

# Get a GHCR auth token via OCI token exchange
oci_token=""
oci_get_token() {
    if [[ -n "$oci_token" ]]; then return; fi

    local cred_token
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        cred_token="$GITHUB_TOKEN"
    elif [[ -n "${GH_TOKEN:-}" ]]; then
        cred_token="$GH_TOKEN"
    else
        cred_token=$(gh auth token 2>/dev/null) || true
    fi
    if [[ -z "$cred_token" ]]; then
        err "No authentication token available for GHCR"
        return 1
    fi

    # Exchange credentials for an OCI registry token
    local scope="repository:${NIXCACHE_REPO}/nix-cache:pull,push"
    local token_response
    token_response=$(curl -s -u "token:${cred_token}" \
        "https://${NIXCACHE_REGISTRY}/token?scope=${scope}&service=${NIXCACHE_REGISTRY}" 2>/dev/null)
    oci_token=$(echo "$token_response" | jq -r '.token // empty' 2>/dev/null)

    if [[ -z "$oci_token" ]]; then
        # Fallback: try the credential directly (some registries accept it)
        oci_token="$cred_token"
    fi
}

# Push a blob to the OCI registry, returns the digest
# oci_push_blob <file>
oci_push_blob() {
    local file="$1"
    oci_get_token

    local digest
    digest="sha256:$(sha256sum "$file" | cut -d' ' -f1)"
    local size
    size=$(stat -c%s "$file")

    # Check if blob already exists
    local check_code
    check_code=$(curl -s -o /dev/null -w '%{http_code}' \
        -H "Authorization: Bearer $oci_token" \
        "https://${NIXCACHE_REGISTRY}/v2/${NIXCACHE_REPO}/nix-cache/blobs/$digest" 2>/dev/null)
    if [[ "$check_code" == "200" ]]; then
        echo "$digest"
        return 0
    fi

    # Initiate upload
    local upload_headers
    upload_headers=$(mktemp)
    curl -s -D "$upload_headers" -o /dev/null \
        -X POST \
        -H "Authorization: Bearer $oci_token" \
        "https://${NIXCACHE_REGISTRY}/v2/${NIXCACHE_REPO}/nix-cache/blobs/uploads/" 2>/dev/null

    local upload_url
    upload_url=$(grep -i '^location:' "$upload_headers" | tr -d '\r' | sed 's/^[Ll]ocation: *//')
    local upload_status
    upload_status=$(head -1 "$upload_headers" | grep -o '[0-9][0-9][0-9]')
    rm -f "$upload_headers"

    if [[ -z "$upload_url" ]]; then
        err "Failed to initiate blob upload (HTTP $upload_status)"
        return 1
    fi

    # Make URL absolute if relative
    if [[ "$upload_url" == /* ]]; then
        upload_url="https://${NIXCACHE_REGISTRY}${upload_url}"
    fi

    # Upload blob in single PUT
    local sep="?"
    [[ "$upload_url" == *"?"* ]] && sep="&"
    local put_code
    put_code=$(curl -s -o /dev/null -w '%{http_code}' \
        -X PUT \
        -H "Authorization: Bearer $oci_token" \
        -H "Content-Type: application/octet-stream" \
        -H "Content-Length: $size" \
        --data-binary "@$file" \
        "${upload_url}${sep}digest=${digest}" 2>/dev/null)

    if [[ "$put_code" != "201" && "$put_code" != "202" ]]; then
        err "Blob upload failed with HTTP $put_code"
        return 1
    fi

    echo "$digest"
}

# Push an OCI manifest and tag it
# oci_push_manifest <tag> <manifest_json>
oci_push_manifest() {
    local tag="$1"
    local manifest="$2"
    oci_get_token

    local code
    code=$(curl -s -o /dev/null -w '%{http_code}' \
        -X PUT \
        -H "Authorization: Bearer $oci_token" \
        -H "Content-Type: application/vnd.oci.image.manifest.v1+json" \
        -d "$manifest" \
        "https://${NIXCACHE_REGISTRY}/v2/${NIXCACHE_REPO}/nix-cache/manifests/${tag}" 2>/dev/null)

    if [[ "$code" != "201" && "$code" != "200" ]]; then
        err "Manifest push failed for tag $tag with HTTP $code"
        return 1
    fi
}

# Fetch a manifest by tag, returns empty string on 404
oci_get_manifest() {
    local tag="$1"
    oci_get_token

    curl -s -f \
        -H "Authorization: Bearer $oci_token" \
        -H "Accept: application/vnd.oci.image.manifest.v1+json" \
        "https://${NIXCACHE_REGISTRY}/v2/${NIXCACHE_REPO}/nix-cache/manifests/${tag}" 2>/dev/null || true
}

# Fetch a blob by digest
oci_get_blob() {
    local digest="$1"
    oci_get_token

    curl -s -f -L \
        -H "Authorization: Bearer $oci_token" \
        "https://${NIXCACHE_REGISTRY}/v2/${NIXCACHE_REPO}/nix-cache/blobs/${digest}" 2>/dev/null
}
