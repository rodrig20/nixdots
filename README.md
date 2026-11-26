# NixOS Configuration

Personal NixOS flake for **NixYo** (Lenovo Yoga Slim 7 14ILL10). Most modules are self-contained and have an `enable` option, so each host turns on only what it needs. Adding a machine means adding a new `hosts/<name>/` directory.

## Documentation

The long-form docs are in the [GitHub wiki](https://github.com/rodrig20/nixdots/wiki). `scripts/generate-wiki.sh` builds those pages from this repository, and `.github/workflows/update-wiki.yml` publishes them on pushes to `main`. Edit `docs/install.md` or the Nix files, not the wiki pages.

- [Install and configuration](https://github.com/rodrig20/nixdots/wiki/Install): fresh install, disk layout, LUKS/TPM2, agenix secrets, host and module configuration
- [System modules](https://github.com/rodrig20/nixdots/wiki/System-Modules): `systemSettings.*` options, services and packages
- [User modules](https://github.com/rodrig20/nixdots/wiki/User-Modules): `userSettings.*` options and Home Manager packages
- [Hardware](https://github.com/rodrig20/nixdots/wiki/Hardware): per-host CPU/GPU profiles
- [Development](https://github.com/rodrig20/nixdots/wiki/Development): templates, cache and proxy tooling, workflows

## Quick start

```bash
git clone git@github.com:rodrig20/nixdots.git ~/nixdots
cd ~/nixdots
sudo nixos-rebuild switch --flake .#nixyo
```

With `systemSettings.nh` enabled and the flake set in the host config, run `sudo nh os switch`.

The fresh install is manual and **DESTRUCTIVE**. Follow the [wiki Install page](https://github.com/rodrig20/nixdots/wiki/Install) instead of doing it from memory. Keep `luks.key` out of git. The `secrets/*.age` files are agenix-encrypted and safe to track.

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

Every file under `modules/*/packages/` is a self-contained module. Add the file, then toggle its option in the host config. No central registry needs updating.

## Contributing to the docs

```bash
# on NixOS:
nix shell nixpkgs#python3 --command bash scripts/generate-wiki.sh /tmp/wiki-out
```
