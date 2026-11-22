# NixOS Configuration

Personal NixOS flake configuration for multiple machines: modules are self-contained and mostly gated by an `enable` option (some also expose options such as vendor paths or credentials), and adding a machine is as simple as creating a `hosts/<name>/` directory.

Currently includes **NixYo** (Lenovo Yoga Slim 7 14ILL10).

## Structure

| Path | Purpose |
|---|---|
| `flake.nix` | Entry point; auto-detects every directory under `hosts/` |
| `lib/` | Helpers (e.g. the recursive module auto-importer) |
| `hosts/<name>/` | One machine per directory: `configuration.nix`, `hardware-configuration.nix`, optional `hardware/<name>.nix` |
| `modules/system/` | System modules under `systemSettings.*` (mostly `<name>.enable`) |
| `modules/user/` | Home Manager modules under `userSettings.*` (mostly `programs.<name>.enable`) |
| `config/` | Static config symlinked into `~/.config` (e.g. `hypr/`) |
| `secrets/` | agenix-encrypted `.age` files |
| `agenix-rules.nix` | Recipients for each secret |
| `templates/` | Flake templates (`base`) |

Within `modules/system/` and `modules/user/`, each subdirectory (and each file under `packages/`) is one self-contained module. Add or remove a module by dropping a file/folder there and toggling its options in the host config. Nothing else needs updating.

## How modules are enabled

Most modules expose an `enable` option under `systemSettings.*` or `userSettings.*`; a few also take values (hostname, kernel, mount points, credentials). Hosts turn on only what they need in `hosts/<name>/configuration.nix`:

```nix
systemSettings = { desktop.enable = true; audio.enable = true; ... };

home-manager.users.rodri.userSettings = {
  shell.enable = true;
  programs.noctalia.enable = true;
  ...
};
```

Software that comes in small, self-contained pieces (like packages/apps) keeps one module per item for individual installs.

## Adding a machine

1. Create `hosts/<name>/configuration.nix` (+ `hardware-configuration.nix`; `hardware/<name>.nix` is optional).
2. Enable only the modules that machine needs.
3. Run `sudo nixos-rebuild switch --flake .#<name>`, the flake auto-detects it.

## Hardware Abstraction

Vendor knobs live in `hosts/<name>/hardware/<name>.nix`:

```nix
{ cpuVendor = "intel"; gpuVendor = "igpu_intel"; }
```

Both values default to `"other"` when the file is absent, so a new host evaluates without vendor-specific tweaks. `modules/system/hardware/cpu/*.nix` and `gpu/*.nix` apply settings via `mkIf` based on `hardware.pc`.

## Project templates

`flake.nix` exposes flake templates for scaffolding new standalone projects:

```bash
nix flake init -t .#base          # local
nix flake init -t github:rodrig20/nixdots#base   # from anywhere
```

Currently available:

| Template | Purpose |
|---|---|
| `base` | Minimal `flake.nix` (`nixpkgs` input + empty `devShells.default`) with a `.envrc` for direnv; extend it as you go |

Each generated project is a single self-contained `flake.nix` with no pre-defined structure. It ships a `.envrc` for **direnv** (enabled via `userSettings.programs.direnv`): `cd` into the project and its devShell packages join your *current* shell (zsh aliases, starship, fzf stay intact). Authorize it once per project with `direnv allow`.

## Deploy

```bash
sudo nixos-rebuild switch --flake .#nixyo
# or, with systemSettings.nh enabled (NH_FLAKE points at this repo):
sudo nh os switch
```
