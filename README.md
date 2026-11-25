# NixOS Configuration

Personal NixOS flake configuration for multiple machines: modules are self-contained and mostly gated by an `enable` option (some also expose options such as vendor paths or credentials), and adding a machine is as simple as creating a `hosts/<name>/` directory.

Currently includes **NixYo** (Lenovo Yoga Slim 7 14ILL10).

## Contents

- [NixOS Configuration](#nixos-configuration)
  - [Contents](#contents)
  - [Repository layout](#repository-layout)
  - [Configuring a host](#configuring-a-host)
    - [How modules are enabled](#how-modules-are-enabled)
    - [Adding a machine](#adding-a-machine)
    - [Hardware abstraction](#hardware-abstraction)
  - [Storage, encryption and secrets](#storage-encryption-and-secrets)
    - [Disk layout and impermanence](#disk-layout-and-impermanence)
    - [LUKS and TPM2](#luks-and-tpm2)
    - [Password secrets (agenix)](#password-secrets-agenix)
  - [Fresh install](#fresh-install)
    - [0. Prepare](#0-prepare)
    - [1. In the installer](#1-in-the-installer)
    - [2. First boot](#2-first-boot)
  - [Deploy](#deploy)
  - [Project templates](#project-templates)
  - [Binary cache](#binary-cache)

## Repository layout

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
| `install.sh` | Destructive fresh-install helper for disko hosts (see [Fresh install](#fresh-install)) |
| `lib/cache-builder.sh`, `lib/cache/` | Binary-cache pipeline (build -> sign -> upload NARs to GHCR), split from [nixcache-oci](https://github.com/cmspam/nixcache-oci) into small files: `oci` (registry API), `paths` (discover/pick), `export` (NARs), `index` (upload), `substituter`, `pipeline` |
| `proxy/` | nixcache-proxy split into `config`/`ghcr`/`index`/`server`/`main`: exposes the GHCR cache as a Nix substituter on `localhost:37515` |
| `templates/` | Flake templates (`base`) |

Within `modules/system/` and `modules/user/`, each subdirectory (and each file under `packages/`) is one self-contained module. Add or remove a module by dropping a file/folder there and toggling its options in the host config. Nothing else needs updating.

## Configuring a host

### How modules are enabled

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

### Adding a machine

1. Create `hosts/<name>/configuration.nix` (+ `hardware-configuration.nix`; `hardware/<name>.nix` is optional).
2. Enable only the modules that machine needs.
3. Run `sudo nixos-rebuild switch --flake .#<name>`; the flake auto-detects it.

### Hardware abstraction

Vendor knobs live in `hosts/<name>/hardware/<name>.nix`:

```nix
{ cpuVendor = "intel"; gpuVendor = "igpu_intel"; }
```

Both values default to `"other"` when the file is absent, so a new host evaluates without vendor-specific tweaks. `modules/system/hardware/cpu/*.nix` and `gpu/*.nix` apply settings via `mkIf` based on `hardware.pc`.

## Storage, encryption and secrets

### Disk layout and impermanence

The disk layout is declarative: `hosts/<name>/disko.nix` creates a GPT with an EFI partition (`/boot`), a swap partition (also `boot.resumeDevice`) and one btrfs partition with subvolumes `root`, `persistent`, `home` and `nix`. Mount options (`compress=zstd:3,noatime`) are declared there, so `systemSettings.btrfs` is skipped on disko hosts.

The root is ephemeral the **native btrfs way**: with impermanence enabled, `modules/system/impermanence.nix` runs a `wipe-root` service in the systemd initrd that moves the current `root` subvolume to `old_roots/<timestamp>` (older than 30 days is deleted) and creates a fresh `root` before `sysroot.mount`. So `/`, `/etc` and `/var` are wiped on every reboot, while `/home`, `/nix` and `/persistent` survive. With impermanence disabled, no wipe service is installed and the same subvolumes are simply mounted. What survives a reboot is declared with [impermanence](https://github.com/nix-community/impermanence), gated by `systemSettings.impermanence.enable` plus `systemSettings.impermanence.persistentStoragePath` (default `/persistent`).

`hardware-configuration.nix` is generated by `nixos-generate-config` and is **not edited**, but it is also **not imported** on disko hosts: `hosts/<name>/hardware.nix` keeps only the detected kernel modules/CPU settings, so regenerating it cannot reintroduce conflicting mounts.

Persistence is **distributed**: each module owns its state and declares it itself, only when both the module and impermanence are on, so a host that doesn't enable impermanence is never touched. The pattern used across `modules/system/`:

```nix
config = lib.mkIf cfg.enable {
  # ... the module's regular settings ...

  # Impermanence: <why this path must survive a reboot>.
  environment.persistence.${config.systemSettings.impermanence.persistentStoragePath} =
    lib.mkIf config.systemSettings.impermanence.enable {
      directories = [ "/var/lib/example" ];
      files = [ "/etc/example.conf" ];
    };
};
```

Where the state currently lives (owner → paths):

| Module | Persisted state |
|---|---|
| `impermanence.nix` (base) | `/etc/machine-id`, `/var/log`, `/var/lib/nixos`, `/var/lib/systemd/coredump` |
| `hardware` | `/var/lib/bluetooth` (paired devices) |
| `networking` | `/etc/NetworkManager/system-connections`; SSH host keys only while `services.openssh.enable` |
| `networking/warp` | `/var/lib/cloudflare-warp` (one-time `warp-cli` registration) |
| `boot/secureboot` | `/var/lib/sbctl` (Secure Boot keys — required to boot in user mode) |
| `packages/ollama` | `/var/lib/ollama` (pulled models) |
| `packages/virtualisation/libvirt` | `/var/lib/libvirt` (imperative VMs) |
| `desktop` | `/var/lib/colord` only while `services.colord.enable` |

The host enables both gates in `hosts/<name>/configuration.nix` and imports `./disko.nix`:

```nix
imports = [ ./hardware.nix ./disko.nix ];

systemSettings = {
  disko = {
    enable = true;
    # Per-host encryption choice (defaults: both false):
    # luks.enable = true;
    # luks.tpm2 = true; # requires luks.enable
  };
  impermanence.enable = true;
};
```

There is no hardcoded UUID/device: disko declares `disko.devices` for the whole disk, the wipe service derives its device from `config.fileSystems."/".device`, and the persistent subvolume name must match the mount point (`persistent` → `/persistent`). `hosts/nixyo/disko.nix` takes `device` as an argument with a placeholder default (`/dev/disk/by-id/DISKO_DEVICE`), so normal flake evaluation works without a disk but running its disko script without `--argstr device` fails loudly.

### LUKS and TPM2

`systemSettings.disko.luks.enable` wraps the btrfs partition (root/persistent/home/nix) in LUKS named `cryptroot`; `/boot` and swap stay plaintext. `systemSettings.disko.luks.tpm2` is independent per host but requires LUKS. Both default to `false`, so existing hosts are unchanged.

`install.sh` reads these options from the chosen host. With LUKS enabled it asks twice for a passphrase (the fallback if TPM2 is unavailable), passes it to disko via a temporary file, and never stores it in the repo. With TPM2 enabled and keys being reused, it runs `systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7` before `nixos-install`; with newly generated keys the enrollment is deferred until after Secure Boot is final. crypttab gets the matching `tpm2-device=auto,tpm2-pcrs=7` options. PCR 7 follows Secure Boot state, so changing Secure Boot keys or firmware invalidates the TPM2 token — keep the passphrase. Auto-unlock adds roughly 0.2–1 s to boot; encryption itself costs a few percent I/O on CPUs with AES-NI, more without it. Without TPM2, boot waits for the passphrase prompt.

The recommended workflow keeps Secure Boot enabled for the whole install, so PCR 7 is the same at enrollment and at the first boot and no re-sealing is needed. If firmware or keys change later, re-seal manually:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/root
```

### Password secrets (agenix)

`/etc/shadow` lives on the wiped root subvolume, so passwords come from two encrypted secrets instead:

| Secret | Feeds | Recipient in `agenix-rules.nix` |
|---|---|---|
| `secrets/nixyo-root-password.age` | `users.users.root.hashedPasswordFile` | `age` |
| `secrets/nixyo-rodri-password.age` | `users.users.<user>.hashedPasswordFile` | `age` |

Both secrets use the same `~/.ssh/id_ed25519_agenix` key and are already encrypted. To change a password:

```bash
openssl passwd -6
echo '<hash>' | nix run github:ryantm/agenix -- -e secrets/nixyo-root-password.age
echo '<hash>' | nix run github:ryantm/agenix -- -e secrets/nixyo-rodri-password.age
```

`passwd` is not enough: `/etc/shadow` is wiped on every boot. `install.sh` copies the agenix key into the target **before** `nixos-install` so activation can decrypt the secrets inside the chroot, and skips the interactive root password.

## Fresh install

`install.sh` is **DESTRUCTIVE**: it wipes the selected disk. It supports two Secure Boot key paths:

- **Reuse existing keys** (default/recommended): Secure Boot stays enabled for the whole install, so PCR 7 never changes and no re-sealing is needed.
- **Generate new keys** (`--create-sbctl-keys`): the firmware must be in Setup Mode. The installer creates and enrolls the keys before the build, and defers TPM2 enrollment until after Secure Boot is enabled in the final reboot.

No first-boot helper script is required in either path.

### 0. Prepare

1. Back up the target disk.
2. Prepare two USB sticks (simplest option):
   - **USB A**: the NixOS ISO written with `dd` to the **whole device**;
   - **USB B**: this repo (`nixdots/`), `id_ed25519_agenix` (private key) and `sbctl/` (the existing keys).

   A single stick with a data partition after the ISO is possible, but less straightforward than two sticks.
3. Firmware depends on the path:
   - **Reuse:** **Secure Boot = Enabled**, keys **not cleared**, Setup Mode off. Booting the ISO with Ventoy and Secure Boot enabled can produce `shim verification error`; if that happens, stop — the enrolled keys are not the expected ones.
   - **New keys:** BIOS -> Secure Boot -> **Clear keys / Setup Mode**, Secure Boot disabled, and no existing keys in the installer's `/var/lib/sbctl`.
4. Note the target disk's `/dev/disk/by-id/...` path.

### 1. In the installer

Boot the ISO from USB A (Secure Boot enabled for reuse, Setup Mode for new keys), then:

```bash
# Mount the data stick
lsblk -f
sudo mkdir -p /run/media/keys
sudo mount /dev/disk/by-label/<LABEL_USB_B> /run/media/keys

# Clone the repo OUTSIDE /mnt (disko mounts the target there)
git clone /run/media/keys/nixdots /root/nixdots
cd /root/nixdots

# Identify the target disk — never assume /dev/nvme0n1
lsblk -d -o NAME,SIZE,MODEL,SERIAL
ls -l /dev/disk/by-id/

# Run the installer
sudo /root/nixdots/install.sh
```

The script asks for the host, the agenix key, the target disk and (with LUKS) the passphrase twice. For Secure Boot keys choose `p` and give `/run/media/keys/sbctl`. Disko prints the disk and asks you to type `yes` before wiping it. The user name comes from the host config, so there is no `--user` flag. Only the selected disk is touched.

To skip the prompts:

```bash
sudo /root/nixdots/install.sh \
  --host nixyo \
  --device /dev/disk/by-id/<id> \
  --agenix-key /run/media/keys/id_ed25519_agenix \
  --sbctl-keys /run/media/keys/sbctl
```

For **new keys**, use `--create-sbctl-keys` instead of `--sbctl-keys` (or choose `g` in the menu). The installer checks Setup Mode, runs `sbctl create-keys`, enrolls them with `sbctl enroll-keys --microsoft`, and copies them to the target. Because firmware state is not final yet, it **does not** enroll a TPM2 token; the exact command to run after the reboot is printed at the end of the install. `--skip-sbctl-keys` also exists but leaves Lanzaboote without signing keys.

The script reads `flake.lock` to run the pinned disko version, sizes swap as `min(RAM,32G)`, then, in order: prepares the keys in `/var/lib/sbctl` (required by Lanzaboote at build time), formats with disko, copies the keys to `/persistent/var/lib/sbctl`, enrolls the TPM2 key when the firmware state is final, stages the agenix key in the target, runs `nixos-install --no-root-password`, fixes the key ownership and checks the results before offering to reboot. Run `install.sh --help` for details.

Equivalent manual steps, if you do not use `install.sh`:

```bash
# 1. DESTRUCTIVE: wipes the disk and creates the partitions/subvolumes.
#    The disk and the RAM size are passed only here, via --argstr; nothing is
#    stored in the repo. Swap = min(RAM, 32 GiB); override with --argstr swapSize 8G.
DISK=/dev/disk/by-id/<id-do-disco>
RAM_GB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount --argstr device "$DISK" --argstr ramGb "$RAM_GB" \
  ./hosts/nixyo/disko.nix

# 2. Stage the agenix key BEFORE installing, so activation can decrypt secrets.
sudo mkdir -p /mnt/home/rodri/.ssh
sudo cp /run/media/keys/id_ed25519_agenix /mnt/home/rodri/.ssh/id_ed25519_agenix
sudo chmod 700 /mnt/home/rodri/.ssh
sudo chmod 600 /mnt/home/rodri/.ssh/id_ed25519_agenix

# 3. Install. The resulting fileSystems/swapDevices use GPT partlabels,
#    so the system never depends on the disk path given above.
sudo nixos-install --flake .#nixyo --no-root-password

# 4. Copy the Secure Boot keys into the persistent subvolume.
sudo mkdir -p /mnt/persistent/var/lib/sbctl
sudo cp -a /run/media/keys/sbctl/. /mnt/persistent/var/lib/sbctl/
```

### 2. First boot

1. Reboot (removing the USB sticks is fine). With reused keys, Secure Boot is already enabled. With new keys, set BIOS -> Secure Boot = **Enabled** before or during this reboot.
2. With reused keys the TPM2 token unlocks LUKS automatically; if it asks for a passphrase, use the LUKS passphrase. With new keys there is no token yet, so the passphrase is expected once.
3. Log in as `rodri` with the password from the secret; `root` also comes from agenix (no root password was requested during the install).
4. Verify:

```bash
ls -l /run/agenix/nixyo-*-password
sudo cryptsetup status cryptroot
sudo sbctl verify
```

5. **Only for new keys**, after Secure Boot is enabled and you are logged in, create the TPM2 token (no `--wipe-slot` is needed because none exists yet):

```bash
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/root
sudo systemd-cryptenroll /dev/disk/by-partlabel/root | grep tpm2
```

From then on LUKS unlocks automatically. With reused keys this check is simply:

```bash
sudo systemd-cryptenroll /dev/disk/by-partlabel/root | grep tpm2
```

The first boot moves the subvolume created by disko into `old_roots/` and creates a fresh `root`; that is expected. `old_roots` is kept for 30 days as a manual rollback point (rename a snapshot back to `root` to recover it); NixOS generations remain in `/nix`.

Inspecting `environment.persistence.<path>.directories` with plain `nix eval --json` currently trips [impermanence#305](https://github.com/nix-community/impermanence/issues/305); use `nix eval --apply 'ds: map (d: d.directory) ds'`. It does not affect evaluation or builds.

## Deploy

```bash
sudo nixos-rebuild switch --flake .#nixyo
# or, with systemSettings.nh enabled (NH_FLAKE points at this repo):
sudo nh os switch
```

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

## Binary cache

Locally-built store paths are published to a self-hosted cache on GHCR (no third-party service), so rebuilds substitute instead of recompiling:

- **Publish** — `.github/workflows/publish-cache.yml` runs the `nixcache-oci` pipeline (`lib/cache-builder.sh`) on every push to `main` that can change the closure. It builds the flake outputs, keeps only paths no upstream cache signs, signs them with `NIX_SIGNING_KEY` and uploads them as OCI blobs to `ghcr.io/rodrig20/nixdots/nix-cache`. `.github/workflows/gc-cache.yml` prunes the index weekly (30-day retention). The scheduled `auto-update` publishes directly through this pipeline after its commit; a push with `GITHUB_TOKEN` does not trigger other workflows, so this step is what updates the cache automatically.
- **CI** — `pr-check.yml` and `auto-update.yml` start the same proxy for the duration of the job (`start_self_substituter` -> builds -> `stop_self_substituter`), so PRs and the daily update download what was already published instead of rebuilding it. The proxy pulls anonymously from the public package (no token is passed); if the cache is missing or empty, every lookup 404s and the build falls back to `cache.nixos.org` exactly as before.
- **Consume** — `systemSettings.nixcache.enable` (see `modules/system/nixcache.nix`) runs `services.nixcache-proxy`, which exposes the GHCR index as an ordinary substituter on `localhost:37515` and streams NARs straight from the registry. The public key lives in `flake.nix` `nixConfig`, so CI and NixOS trust the same signatures.

One-time setup:

1. Generate the key pair and store the secret on GitHub (Settings -> Secrets and variables -> Actions -> `NIX_SIGNING_KEY`); the public half is already pinned in `flake.nix`.
   ```bash
   nix key generate-secret --key-name rodrig20-nixdots   # -> NIX_SIGNING_KEY secret
   ```
2. After the first publish run, set the package `ghcr.io/rodrig20/nixdots/nix-cache` to **Public** so the proxy can pull it anonymously.
