# NixOS Configuration

Personal NixOS flake for **NixYo** (Lenovo Yoga Slim 7 14ILL10). Modules are self-contained and mostly gated by an `enable` option; a host enables only what it needs. Adding a machine is just a new `hosts/<name>/` directory.

## Documentation

The long-form docs live in the [GitHub wiki](https://github.com/rodrig20/nixdots/wiki), generated from the source tree by `scripts/generate-wiki.sh` (`.github/workflows/update-wiki.yml` publishes it on pushes to `main`). Edit the Nix files or `docs/install.md` — **do not edit the wiki pages by hand**.

- [Install and configuration](https://github.com/rodrig20/nixdots/wiki/Install) — fresh install, disk layout, LUKS/TPM2, agenix secrets, host/module configuration
- [System modules](https://github.com/rodrig20/nixdots/wiki/System-Modules) — `systemSettings.*` options, services, packages
- [User modules](https://github.com/rodrig20/nixdots/wiki/User-Modules) — `userSettings.*` options and Home Manager packages
- [Hardware](https://github.com/rodrig20/nixdots/wiki/Hardware) — per-host CPU/GPU profiles
- [Development](https://github.com/rodrig20/nixdots/wiki/Development) — templates, cache/proxy tooling, workflows

## Quick start

```bash
git clone git@github.com:rodrig20/nixdots.git ~/nixdots
cd ~/nixdots
sudo nixos-rebuild switch --flake .#nixyo
```

With `systemSettings.nh` enabled and the flake set in the host config: `sudo nh os switch`

The fresh install is **DESTRUCTIVE** and manual — follow the [wiki Install page](https://github.com/rodrig20/nixdots/wiki/Install) instead of doing it from memory. Keep `luks.key` out of git; `secrets/*.age` are agenix-encrypted and safe to track.

## Repository layout

| Path | Purpose |
|---|---|
| `flake.nix` | Entry point; auto-detects every directory under `hosts/` |
| `hosts/<name>/` | One machine per directory: `configuration.nix`, `hardware-configuration.nix`, optional `hardware/<name>.nix` |
| `modules/system/` | System modules under `systemSettings.*` (mostly `<name>.enable`) |
| `modules/user/` | Home Manager modules under `userSettings.*` (mostly `programs.<name>.enable`) |
| `config/` | Static config symlinked into `~/.config` (e.g. `hypr/`) |
| `docs/install.md` | Source for the wiki Install page |
| `scripts/generate-wiki.sh` | Generates the wiki pages from this tree |
| `secrets/`, `agenix-rules.nix` | agenix-encrypted secrets and their recipients |
| `lib/`, `proxy/`, `templates/` | Module importer, binary cache pipeline/proxy, flake template |

Every file under `modules/*/packages/` is one self-contained module: drop the file in and toggle its option in the host config — no central registry to update.

## Contributing to the docs

```bash
# on NixOS:
nix shell nixpkgs#python3 --command bash scripts/generate-wiki.sh /tmp/wiki-out
```
