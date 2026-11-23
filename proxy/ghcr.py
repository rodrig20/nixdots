"""GHCR/OCI registry access: token exchange, blob fetch and streaming."""
import base64
import json
import time
import urllib.request

from config import GITHUB_TOKEN, REPO, REGISTRY, UPSTREAM_CACHES, fetch_url, open_stream

# ── OCI auth ──────────────────────────────────────────────────────────

_oci_token: str = ""
_oci_token_time: float = 0.0


def get_oci_token() -> str:
    global _oci_token, _oci_token_time
    if _oci_token and (time.time() - _oci_token_time) < 240:
        return _oci_token

    if GITHUB_TOKEN:
        scope = f"repository:{REPO}/nix-cache:pull"
        token_url = f"https://{REGISTRY}/token?scope={scope}&service={REGISTRY}"
        creds = base64.b64encode(f"token:{GITHUB_TOKEN}".encode()).decode()
        req = urllib.request.Request(token_url)
        req.add_header("Authorization", f"Basic {creds}")
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read())
                _oci_token = data.get("token", GITHUB_TOKEN)
                _oci_token_time = time.time()
                return _oci_token
        except Exception:
            _oci_token = GITHUB_TOKEN
            _oci_token_time = time.time()
            return _oci_token

    # Anonymous token
    scope = f"repository:{REPO}/nix-cache:pull"
    token_url = f"https://{REGISTRY}/token?scope={scope}&service={REGISTRY}"
    data = fetch_url(token_url)
    if data:
        try:
            _oci_token = json.loads(data).get("token", "")
            _oci_token_time = time.time()
            return _oci_token
        except json.JSONDecodeError:
            pass
    return ""


def ghcr_headers() -> dict:
    token = get_oci_token()
    h = {"Accept": "application/vnd.oci.image.manifest.v1+json"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    return h


def ghcr_fetch(path: str) -> bytes | None:
    url = f"https://{REGISTRY}/v2/{REPO}/nix-cache{path}"
    return fetch_url(url, ghcr_headers())


def ghcr_fetch_blob(digest: str) -> bytes | None:
    url = f"https://{REGISTRY}/v2/{REPO}/nix-cache/blobs/{digest}"
    return fetch_url(url, ghcr_headers(), timeout=120)


def ghcr_stream_blob(digest: str):
    """Open a streaming connection to a GHCR blob. Returns (response, content_length) or (None, 0)."""
    url = f"https://{REGISTRY}/v2/{REPO}/nix-cache/blobs/{digest}"
    return open_stream(url, ghcr_headers())


def upstream_stream_nar(path: str):
    """Try to open a streaming connection to an upstream cache NAR. Returns (response, content_length) or (None, 0)."""
    for cache_url in UPSTREAM_CACHES:
        resp, length = open_stream(f"{cache_url}{path}", timeout=60)
        if resp is not None:
            return resp, length
    return None, 0
