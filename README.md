# NixOS Configuration

Personal NixOS flake configuration for multiple machines: every module is self-contained behind an `enable` option, and adding a machine is as simple as creating a `hosts/<name>/` directory.

Currently includes **NixYo** (Lenovo Yoga Slim 7 14ILL10).

## Structure

| Path | Purpose |
|---|---|
| `flake.nix` | Entry point; auto-detects every directory under `hosts/` |
| `lib/` | Helpers (e.g. the recursive module auto-importer) |
| `hosts/<name>/` | One machine per directory: `configuration.nix`, `hardware-configuration.nix`, `hardware/<name>.nix` |
| `modules/system/` | System-level modules, each gated by `systemSettings.<name>.enable` |
| `modules/user/` | Home Manager modules, each gated by `userSettings.<name>.enable` |
| `config/` | Static config symlinked into `~/.config` (e.g. `hypr/`) |

Within `modules/system/` and `modules/user/`, each subdirectory (and each file under `packages/`) is one self-contained module. Add or remove a module by dropping a file/folder there and toggling its `enable` option in the host config. Nothing else needs updating.

## How modules are enabled

Each module in `modules/system` and `modules/user` gates itself behind an `enable` option. Hosts turn on only what they need in `hosts/<name>/configuration.nix`:

```nix
systemSettings = { desktop.enable = true; audio.enable = true; ... };
home-manager.users.rodri.userSettings = { shell.enable = true; noctalia.enable = true; ... };
```

Software that comes in small, self-contained pieces (like packages/apps) keeps one module per item for individual installs.

## Adding a machine

1. Create `hosts/<name>/configuration.nix` (+ `hardware-configuration.nix`, `hardware/<name>.nix`).
2. Enable only the modules that machine needs.
3. Run `sudo nixos-rebuild switch --flake .#<name>`, the flake auto-detects it.

## Hardware Abstraction

Vendor knobs live in `hosts/<name>/hardware/<name>.nix`:

```nix
{ cpuVendor = "intel"; gpuVendor = "igpu_intel"; }
```

`modules/system/hardware/cpu/*.nix` and `gpu/*.nix` apply settings via `mkIf` based on `hardware.pc`.


## Project templates

`flake.nix` exposes flake templates for scaffolding new standalone projects:

```bash
nix flake init -t .#base          # local
nix flake init -t github:rodri/nixdots#base   # from anywhere
```

Currently available:

| Template | Purpose |
|---|---|
| `base` | Just a `flake.nix` (only `nixpkgs` input + empty `devShells.default`); no structure or docs, extend it as you go |

Each generated project is a single self-contained `flake.nix` with no pre-defined structure.

## Deploy

```bash
sudo nixos-rebuild switch --flake .#nixyo
```
