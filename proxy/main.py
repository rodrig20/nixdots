#!/usr/bin/env python3
# Split from cmspam/nixcache-oci @ 838bed6046ff2f0428b49485ebd07269cd0fc399,
# which ships proxy/main.py as a single file. To re-sync, fetch that file and
# re-apply the split across config.py / ghcr.py / index.py / server.py.
"""
nixcache-proxy — Local HTTP proxy bridging Nix binary cache protocol to GHCR.

Serves narinfo responses from a locally-cached index (zero network latency).
Streams NAR blobs directly from GHCR or upstream caches to Nix — no disk
caching, no buffering entire files into memory.
"""
import http.server
import signal
import sys
import threading

from config import INDEX_TTL, LISTEN_ADDR, PORT, REPO, UPSTREAM_CACHES
from index import cache_index
from server import CacheHandler

def main():
    print(f"nixcache-proxy starting on http://{LISTEN_ADDR}:{PORT}", file=sys.stderr)
    print(f"  Repo: {REPO}", file=sys.stderr)
    print(f"  Upstream: {', '.join(UPSTREAM_CACHES)}", file=sys.stderr)
    print(f"  Index TTL: {INDEX_TTL}s", file=sys.stderr)

    server = http.server.ThreadingHTTPServer((LISTEN_ADDR, PORT), CacheHandler)

    # Pre-fetch index in background so server starts immediately
    threading.Thread(target=cache_index.get, daemon=True).start()

    def shutdown(signum, frame):
        # server.shutdown() blocks until serve_forever() returns. If we call
        # it from this signal handler — which runs on the same thread as
        # serve_forever() — we deadlock: serve_forever() can't exit until
        # the handler returns, the handler can't return until shutdown()
        # exits. systemd then waits TimeoutStopSec (default 90s) before
        # SIGKILL. Spin shutdown() off in a separate thread so the handler
        # returns immediately and serve_forever()'s loop notices the
        # shutdown flag and exits cleanly within milliseconds.
        print("\nShutting down...", file=sys.stderr)
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    server.serve_forever()


if __name__ == "__main__":
    main()
