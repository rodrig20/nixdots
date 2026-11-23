"""Cache-index: store hash -> narinfo + NAR blob digest, mirrored to disk."""
import json
import sys
import threading
import time

from config import INDEX_DIR, INDEX_TTL
from ghcr import ghcr_fetch, ghcr_fetch_blob

# ── Index ─────────────────────────────────────────────────────────────

class CacheIndex:
    def __init__(self):
        self._index: dict | None = None
        self._lock = threading.Lock()
        self._last_fetch = 0.0
        self._index_file = INDEX_DIR / "cache-index.json"

    def get(self) -> dict:
        with self._lock:
            if time.time() - self._last_fetch > INDEX_TTL:
                self._refresh()
            return self._index or {"entries": {}, "gc_roots": []}

    def force_refresh(self) -> int:
        with self._lock:
            self._last_fetch = 0.0
            self._refresh()
            entries = self._index.get("entries", {}) if self._index else {}
            return len(entries)

    def _refresh(self):
        manifest_data = ghcr_fetch("/manifests/cache-index")
        if manifest_data:
            try:
                manifest = json.loads(manifest_data)
                layers = manifest.get("layers", [])
                if layers:
                    index_digest = layers[0]["digest"]
                    index_data = ghcr_fetch_blob(index_digest)
                    if index_data:
                        self._index = json.loads(index_data)
                        self._index_file.parent.mkdir(parents=True, exist_ok=True)
                        self._index_file.write_bytes(index_data)
                        print(f"[nixcache-proxy] Index refreshed: "
                              f"{len(self._index.get('entries', {}))} entries",
                              file=sys.stderr)
            except (json.JSONDecodeError, KeyError):
                pass

        if not self._index and self._index_file.exists():
            try:
                self._index = json.loads(self._index_file.read_bytes())
            except json.JSONDecodeError:
                pass

        self._last_fetch = time.time()

    def lookup(self, store_hash: str) -> dict | None:
        index = self.get()
        return index.get("entries", {}).get(store_hash)

    def find_nar_digest(self, nar_basename: str) -> str | None:
        """Find the OCI blob digest for a NAR file by searching narinfo URL fields."""
        index = self.get()
        for _hash, entry in index.get("entries", {}).items():
            narinfo = entry.get("narinfo", "")
            for line in narinfo.split("\n"):
                if line.startswith("URL: ") and nar_basename in line:
                    return entry.get("nar_digest")
        return None


cache_index = CacheIndex()
