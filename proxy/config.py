"""Configuration and generic HTTP helpers for nixcache-proxy."""
import os
import urllib.error
import urllib.request
from pathlib import Path

REPO = os.environ.get("NIXCACHE_REPO", "cmspam/mynixcache-oci")
REGISTRY = os.environ.get("NIXCACHE_REGISTRY", "ghcr.io")
PORT = int(os.environ.get("NIXCACHE_PORT", "37515"))
LISTEN_ADDR = os.environ.get("NIXCACHE_LISTEN", "127.0.0.1")
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", os.environ.get("GH_TOKEN", ""))
def _default_index_dir() -> Path:
    # Honour an explicit NIXCACHE_INDEX_DIR first, then systemd's
    # $CACHE_DIRECTORY (set when the unit declares CacheDirectory=),
    # and only fall back to $HOME/.cache if neither is set. DynamicUser
    # services have no writable home — falling through to Path.home()
    # there gets you /.cache on a read-only root fs, which then crashes
    # every request with an OSError.
    explicit = os.environ.get("NIXCACHE_INDEX_DIR")
    if explicit:
        return Path(explicit)
    cache_dir = os.environ.get("CACHE_DIRECTORY")
    if cache_dir:
        return Path(cache_dir)
    return Path.home() / ".cache" / "nixcache-proxy" / REPO.replace("/", "--")


INDEX_DIR = _default_index_dir()
INDEX_TTL = int(os.environ.get("NIXCACHE_INDEX_TTL", "300"))  # seconds
UPSTREAM_CACHES = os.environ.get("NIXCACHE_UPSTREAM", "https://cache.nixos.org").split()
STREAM_CHUNK_SIZE = 64 * 1024  # 64 KB chunks for streaming


def fetch_url(url: str, headers: dict | None = None, timeout: int = 60) -> bytes | None:
    """Fetch a URL fully into memory. Used for small responses (narinfo, index)."""
    req = urllib.request.Request(url)
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read()
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
        return None


def open_stream(url: str, headers: dict | None = None, timeout: int = 120):
    """Open a streaming connection to a URL. Returns (response, content_length) or (None, 0)."""
    req = urllib.request.Request(url)
    if headers:
        for k, v in headers.items():
            req.add_header(k, v)
    try:
        resp = urllib.request.urlopen(req, timeout=timeout)
        length = resp.headers.get("Content-Length")
        return resp, int(length) if length else None
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError):
        return None, 0
