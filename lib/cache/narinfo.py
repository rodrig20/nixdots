import json, sys, os

store_path = sys.argv[1]
hash_prefix = sys.argv[2]
nar_file = sys.argv[3]
file_size = int(sys.argv[4])
file_hash = sys.argv[5]
cache_dir = sys.argv[6]

info = json.loads(sys.argv[7])
# nix path-info --json returns a list or dict depending on version
if isinstance(info, list):
    info = info[0]
elif isinstance(info, dict) and store_path in info:
    info = info[store_path]

nar_hash = info.get('narHash', '')
nar_size = info.get('narSize', 0)
refs = info.get('references', [])
deriver = info.get('deriver', '')
sigs = info.get('signatures', info.get('sigs', []))

# Build references as just the basename of each ref path
ref_names = ' '.join(os.path.basename(r) for r in refs)

lines = [
    f'StorePath: {store_path}',
    f'URL: nar/{hash_prefix}.nar.xz',
    f'Compression: xz',
    f'FileHash: sha256:{file_hash}',
    f'FileSize: {file_size}',
    f'NarHash: {nar_hash}',
    f'NarSize: {nar_size}',
]
if ref_names:
    lines.append(f'References: {ref_names}')
if deriver:
    lines.append(f'Deriver: {os.path.basename(deriver)}')
for sig in sigs:
    lines.append(f'Sig: {sig}')

narinfo_path = os.path.join(cache_dir, f'{hash_prefix}.narinfo')
with open(narinfo_path, 'w') as f:
    f.write('\n'.join(lines) + '\n')
