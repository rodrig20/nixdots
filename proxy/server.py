"""HTTP side of the proxy: speaks the Nix binary-cache protocol."""
import http.server
import json
import sys

from config import INDEX_TTL, REPO, STREAM_CHUNK_SIZE, UPSTREAM_CACHES, fetch_url
from ghcr import ghcr_stream_blob, upstream_stream_nar
from index import cache_index

# ── HTTP handler ──────────────────────────────────────────────────────

def get_nci_response() -> bytes:
    lines = [
        "StoreDir: /nix/store",
        "WantMassQuery: 1",
        "Priority: 40",
    ]
    return "\n".join(lines).encode() + b"\n"


class CacheHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        sys.stderr.write(f"[nixcache-proxy] {args[0]}\n")

    def do_GET(self):
        path = self.path.rstrip("/")
        if path == "/nix-cache-info":
            self._serve_bytes(get_nci_response(), "text/x-nix-cache-info")
        elif path == "/public-key":
            self._serve_public_key()
        elif path == "/_status":
            self._serve_status()
        elif path.endswith(".narinfo"):
            self._serve_narinfo(path)
        elif path.startswith("/nar/"):
            self._serve_nar(path)
        else:
            self.send_error(404)

    def do_POST(self):
        path = self.path.rstrip("/")
        if path == "/_refresh":
            self._handle_refresh()
        else:
            self.send_error(404)

    def _serve_bytes(self, data: bytes, content_type: str):
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _stream_response(self, resp, content_length: int | None, content_type: str):
        """Stream an upstream response directly to the client."""
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        if content_length is not None:
            self.send_header("Content-Length", str(content_length))
        self.end_headers()
        while True:
            chunk = resp.read(STREAM_CHUNK_SIZE)
            if not chunk:
                break
            self.wfile.write(chunk)

    def _serve_public_key(self):
        index = cache_index.get()
        pk = index.get("public_key", "")
        if pk:
            self._serve_bytes(pk.encode() + b"\n", "text/plain")
        else:
            self.send_error(404, "No public key configured")

    def _serve_status(self):
        index = cache_index.get()
        status = {
            "index_entries": len(index.get("entries", {})),
            "index_generated": index.get("generated", "unknown"),
            "index_ttl": INDEX_TTL,
            "repo": REPO,
            "upstream": UPSTREAM_CACHES,
        }
        body = json.dumps(status, indent=2).encode() + b"\n"
        self._serve_bytes(body, "application/json")

    def _handle_refresh(self):
        count = cache_index.force_refresh()
        body = json.dumps({"refreshed": True, "entries": count}).encode() + b"\n"
        self._serve_bytes(body, "application/json")

    def _serve_narinfo(self, path: str):
        store_hash = path.lstrip("/").removesuffix(".narinfo")

        # Look up in our OCI index — instant, no network
        entry = cache_index.lookup(store_hash)
        if entry and "narinfo" in entry:
            body = entry["narinfo"].encode("utf-8")
            self._serve_bytes(body, "text/x-nix-narinfo")
            return

        # Fall back to upstream
        for cache_url in UPSTREAM_CACHES:
            data = fetch_url(f"{cache_url}/{store_hash}.narinfo", timeout=10)
            if data is not None:
                self._serve_bytes(data, "text/x-nix-narinfo")
                return

        self.send_error(404)

    def _serve_nar(self, path: str):
        nar_basename = path.removeprefix("/nar/")
        ct = "application/x-xz" if nar_basename.endswith(".xz") else "application/x-nix-nar"

        # Try our GHCR cache — stream directly
        nar_digest = cache_index.find_nar_digest(nar_basename)
        if nar_digest:
            resp, length = ghcr_stream_blob(nar_digest)
            if resp is not None:
                self._stream_response(resp, length, ct)
                resp.close()
                return

        # Fall back to upstream — stream directly
        resp, length = upstream_stream_nar(path)
        if resp is not None:
            self._stream_response(resp, length, ct)
            resp.close()
            return

        self.send_error(404)
