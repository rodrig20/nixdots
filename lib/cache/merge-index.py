import json, os

with open(os.environ["EXISTING_INDEX_FILE"]) as f:
    try:
        existing = json.load(f)
    except json.JSONDecodeError:
        existing = {}

with open(os.environ["GC_ROOTS_FILE"]) as f:
    new_gc_roots = json.load(f)

new_entries = {}
with open(os.environ["RECEIPTS_FILE"]) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        r = json.loads(line)
        with open(r["narinfo_file"]) as nf:
            narinfo = nf.read()
        store_path = ""
        for l in narinfo.splitlines():
            if l.startswith("StorePath: "):
                store_path = l[len("StorePath: "):].strip()
                break
        name = (
            os.path.basename(store_path).split("-", 1)[-1]
            if store_path else r["hash"]
        )
        new_entries[r["hash"]] = {
            "name": name,
            "narinfo": narinfo,
            "nar_digest": r["nar_digest"],
            "nar_size": int(r["nar_size"]),
            "added": os.environ["GENERATED_AT"],
        }

index = {
    "version": 1,
    "repo": os.environ["NIXCACHE_REPO"],
    "registry": os.environ["NIXCACHE_REGISTRY"],
    "image": os.environ["NIXCACHE_IMAGE"],
    "generated": os.environ["GENERATED_AT"],
    "public_key": os.environ["PUBLIC_KEY"] or existing.get("public_key", ""),
    "entries": {},
    "gc_roots": [],
}

index["entries"].update(existing.get("entries", {}))
index["entries"].update(new_entries)

index["gc_roots"] = sorted(
    set(existing.get("gc_roots", [])) | set(new_gc_roots)
)

with open(os.environ["OUTPUT_FILE"], "w") as f:
    json.dump(index, f, indent=2, sort_keys=True)

print(
    f">>> Cache index rebuilt: {len(index['entries'])} total entries "
    f"({len(new_entries)} new), {len(index['gc_roots'])} gc roots"
)
