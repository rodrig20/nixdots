#!/usr/bin/env bash
# Fresh install of nixdots: disko (GPT/btrfs/swap) + NixOS + native impermanence.
#
# Run from a NixOS installer, AFTER cloning this repo outside /mnt:
#   sudo /root/nixdots/install.sh
#
# DESTRUCTIVE: it wipes the target disk. Only the agenix SSH key is restored.
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOST=""
DEVICE=""
AGENIX_KEY=""
SBCTL_KEYS=""
CREATE_SBCTL_KEYS=false
SKIP_SBCTL_KEYS=false
ROOT_MOUNTPOINT="/mnt"

usage() {
  cat <<EOF
Usage: $0 [options]

The script asks for the host, the disk and the agenix SSH key when omitted.

Options:
  --host NAME            host directory under hosts/NAME
  --device DEVICE        whole disk, preferably /dev/disk/by-id/...
  --agenix-key FILE      agenix SSH private key, copied to the user's ~/.ssh
  --sbctl-keys DIR       Secure Boot keys to copy into /persistent/var/lib/sbctl
  --create-sbctl-keys    generate new keys with sbctl (requires Setup Mode)
  --skip-sbctl-keys      continue without Secure Boot keys (warns at the end)
  -h, --help             show this help

Example:
  sudo $0 --host nixyo --device /dev/disk/by-id/<id> \\
    --agenix-key /run/media/usb/id_ed25519_agenix --sbctl-keys /run/media/usb/sbctl
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }

while (($#)); do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --device) DEVICE="$2"; shift 2 ;;
    --agenix-key) AGENIX_KEY="$2"; shift 2 ;;
    --sbctl-keys) SBCTL_KEYS="$2"; shift 2 ;;
    --create-sbctl-keys) CREATE_SBCTL_KEYS=true; shift ;;
    --skip-sbctl-keys) SKIP_SBCTL_KEYS=true; shift ;;
    -h | --help) usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
done

# --- Preflight -------------------------------------------------------------
[[ $EUID -eq 0 ]] || die "run as root in the installer"
command -v nix >/dev/null || die "nix not found — boot from the NixOS installer"
command -v nixos-install >/dev/null || die "nixos-install not found"
[[ -f "$REPO_ROOT/flake.nix" ]] || die "flake.nix not found in $REPO_ROOT"
[[ "$REPO_ROOT" != "$ROOT_MOUNTPOINT"* ]] || die "the repo must not live under $ROOT_MOUNTPOINT (disko mounts the target there)"

if [[ -z "$HOST" ]]; then
  info "Available hosts:"
  for dir in "$REPO_ROOT"/hosts/*/; do
    [[ -d "$dir" ]] && printf '  %s\n' "$(basename "$dir")"
  done
  printf '\nHost name: '
  read -r HOST
fi
[[ "$HOST" =~ ^[A-Za-z0-9_-]+$ ]] || die "invalid host name: $HOST"
[[ -f "$REPO_ROOT/hosts/$HOST/disko.nix" ]] || die "missing hosts/$HOST/disko.nix"
[[ -f "$REPO_ROOT/hosts/$HOST/hardware.nix" ]] || die "missing hosts/$HOST/hardware.nix"

# Derive the user and the per-host disk security choices from the host config.
HOST_INFO="$(REPO_REF="path:$REPO_ROOT" HOST="$HOST" nix --extra-experimental-features "nix-command flakes" eval --impure --raw --expr \
  'let c = (builtins.getFlake (builtins.getEnv "REPO_REF")).nixosConfigurations.${builtins.getEnv "HOST"}.config;
     b = v: if v then "true" else "false";
   in "${c.systemSettings.users.name} ${b c.systemSettings.disko.luks.enable} ${b c.systemSettings.disko.luks.tpm2} ${c.boot.initrd.luks.devices.cryptroot.device or ""}"')"
read -r USER_NAME LUKS_ENABLED TPM2_ENABLED LUKS_DEVICE <<< "$HOST_INFO"
[[ -n "$USER_NAME" ]] || die "could not read the user name from $HOST"
[[ "$TPM2_ENABLED" != "true" || "$LUKS_ENABLED" == "true" ]] || \
  die "TPM2 requires systemSettings.disko.luks.enable for host $HOST"
info "Host: $HOST | user: $USER_NAME | LUKS: $LUKS_ENABLED | TPM2: $TPM2_ENABLED"

if [[ -z "$AGENIX_KEY" ]]; then
  printf 'Path to the agenix SSH private key: '
  read -r AGENIX_KEY
fi
[[ -f "$AGENIX_KEY" ]] || die "agenix key not found: $AGENIX_KEY"

if [[ -z "$DEVICE" ]]; then
  info "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL,SERIAL
  printf '\nTarget disk (e.g. /dev/disk/by-id/nvme-...): '
  read -r DEVICE
fi
[[ -b "$DEVICE" ]] || die "$DEVICE is not a block device"
[[ "$(lsblk -dno TYPE "$DEVICE" 2>/dev/null)" == "disk" ]] || die "$DEVICE is not a whole disk"
if lsblk -nro MOUNTPOINT "$DEVICE" 2>/dev/null | grep -q .; then
  die "$DEVICE has mounted partitions — unmount them first"
fi

# LUKS passphrase: kept as the fallback when TPM2 is unavailable. Disko gets it
# through a temporary file so it is never written to the repo or the disk.
LUKS_KEY_FILE=""
if [[ "$LUKS_ENABLED" == "true" ]]; then
  printf '\nLUKS passphrase (fallback if TPM2 fails): '
  read -r -s luks_pass1
  printf '\nConfirm LUKS passphrase: '
  read -r -s luks_pass2
  printf '\n'
  [[ -n "$luks_pass1" && "$luks_pass1" == "$luks_pass2" ]] || die "LUKS passphrases do not match or are empty"
  LUKS_KEY_FILE="$(mktemp)"
  chmod 600 "$LUKS_KEY_FILE"
  printf '%s' "$luks_pass1" > "$LUKS_KEY_FILE"
  trap 'rm -f "$LUKS_KEY_FILE"' EXIT
  unset luks_pass1 luks_pass2
  ok "LUKS passphrase captured — store it outside this machine"
fi

# Ask before the destructive step so a bad choice cannot waste the install.
if [[ -n "$SBCTL_KEYS" ]]; then
  KEY_MODE=path
elif $CREATE_SBCTL_KEYS; then
  KEY_MODE=generate
elif $SKIP_SBCTL_KEYS; then
  KEY_MODE=skip
else
  printf '\nSecure Boot keys: [p]rovide path, [g]enerate new, [s]kip: '
  read -r choice
  case "$choice" in
    p | P)
      printf 'Directory containing the keys: '
      read -r SBCTL_KEYS
      KEY_MODE=path
      ;;
    g | G) KEY_MODE=generate ;;
    s | S) KEY_MODE=skip ;;
    *) die "invalid choice: $choice" ;;
  esac
fi

# Disko prints the disk it will wipe and asks for "yes" before destroying it.

# --- Disko -----------------------------------------------------------------
RAM_GB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
DISKO_REV="$(cd "$REPO_ROOT" && nix --extra-experimental-features "nix-command flakes" eval --impure --raw --expr \
  'let l = builtins.fromJSON (builtins.readFile ./flake.lock); in l.nodes.disko.locked.rev')"
info "Host: $HOST | disk: $DEVICE | RAM: ${RAM_GB} GiB | swap: min(RAM,32G) | disko: ${DISKO_REV:0:12}"
info "Formatting (destructive)..."
DISKO_ARGS=(
  --mode destroy,format,mount
  --argstr device "$DEVICE"
  --argstr ramGb "$RAM_GB"
)
if [[ "$LUKS_ENABLED" == "true" ]]; then
  DISKO_ARGS+=(
    --argstr luks true
    --argstr tpm2 "$TPM2_ENABLED"
    --argstr passwordFile "$LUKS_KEY_FILE"
  )
fi
nix --extra-experimental-features "nix-command flakes" run "github:nix-community/disko/$DISKO_REV" -- \
  "${DISKO_ARGS[@]}" "$REPO_ROOT/hosts/$HOST/disko.nix"
ok "subvolumes root/persistent/home/nix created and mounted under $ROOT_MOUNTPOINT"

# --- TPM2 enrollment --------------------------------------------------------
# Disko creates the LUKS header but does not enroll a TPM2 key. PCR 7 matches
# crypttabExtraOpts in hosts/$HOST/disko.nix (Secure Boot state).
if [[ "$LUKS_ENABLED" == "true" && "$TPM2_ENABLED" == "true" ]]; then
  [[ -n "$LUKS_DEVICE" ]] || die "could not read the LUKS device from $HOST config"
  info "Enrolling TPM2 key in $LUKS_DEVICE (PCR 7)..."
  if command -v systemd-cryptenroll >/dev/null; then
    systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
      --unlock-key-file="$LUKS_KEY_FILE" "$LUKS_DEVICE"
  else
    nix --extra-experimental-features "nix-command flakes" shell nixpkgs#systemd -c \
      systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
      --unlock-key-file="$LUKS_KEY_FILE" "$LUKS_DEVICE"
  fi
  ok "TPM2 key enrolled"
fi

# --- Agenix key -------------------------------------------------------------
# Copy BEFORE nixos-install: activation decrypts the password secrets inside
# the target chroot and needs a readable identity there. /home is persistent.
SSH_DIR="$ROOT_MOUNTPOINT/home/$USER_NAME/.ssh"
mkdir -p "$SSH_DIR"
cp "$AGENIX_KEY" "$SSH_DIR/id_ed25519_agenix"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/id_ed25519_agenix"
ok "agenix key staged at $SSH_DIR/id_ed25519_agenix"

# --- NixOS -----------------------------------------------------------------
info "Installing $HOST..."
# The durable root password comes from agenix; the interactive one would be
# wiped by impermanence on the first boot anyway.
nixos-install --flake "$REPO_ROOT#$HOST" --no-root-password
ok "generation installed"

# /etc/passwd and /etc/group now exist in the target, so fix the ownership.
USER_UID="$(awk -F: -v u="$USER_NAME" '$1 == u { print $3; exit }' "$ROOT_MOUNTPOINT/etc/passwd" 2>/dev/null || true)"
USER_GID="$(awk -F: '$1 == "users" { print $3; exit }' "$ROOT_MOUNTPOINT/etc/group" 2>/dev/null || true)"
chown -R "${USER_UID:-1000}:${USER_GID:-100}" "$SSH_DIR"
ok "agenix key installed at $SSH_DIR/id_ed25519_agenix"

# --- Secure Boot -----------------------------------------------------------
KEY_DEST="$ROOT_MOUNTPOINT/persistent/var/lib/sbctl"
case "$KEY_MODE" in
  path)
    [[ -d "$SBCTL_KEYS" ]] || die "key directory not found: $SBCTL_KEYS"
    mkdir -p "$KEY_DEST"
    cp -a "$SBCTL_KEYS/." "$KEY_DEST/"
    ok "Secure Boot keys copied to $KEY_DEST"
    ;;
  generate)
    info "Generating Secure Boot keys (requires Setup Mode)..."
    nix --extra-experimental-features "nix-command flakes" shell nixpkgs#sbctl -c sbctl create-keys
    mkdir -p "$KEY_DEST"
    cp -a /var/lib/sbctl/. "$KEY_DEST/"
    ok "Secure Boot keys generated and copied to $KEY_DEST"
    printf '  New keys also need: nix shell nixpkgs#sbctl -c sbctl enroll-keys --microsoft\n'
    ;;
  skip)
    printf '  WARNING: no Secure Boot keys in %s — user mode may fail.\n' "$KEY_DEST"
    ;;
esac

# --- Final checks ----------------------------------------------------------
info "Checks before reboot:"
for path in "$KEY_DEST" "$SSH_DIR/id_ed25519_agenix"; do
  if [[ -e "$path" ]]; then ok "$path"; else printf '  ! missing: %s\n' "$path"; fi
done
if [[ "$LUKS_ENABLED" == "true" ]]; then
  if [[ "$TPM2_ENABLED" == "true" ]] && command -v systemd-cryptenroll >/dev/null \
    && systemd-cryptenroll "$LUKS_DEVICE" 2>/dev/null | grep -qw tpm2; then
    ok "TPM2 token enrolled in $LUKS_DEVICE"
  else
    printf '  ! no TPM2 token found — the LUKS passphrase is required at boot\n'
  fi
  printf '  Keep the LUKS passphrase: firmware/Secure Boot key changes invalidate TPM2.\n'
fi

printf '\nDone. Reboot now? [y/N]: '
read -r answer
if [[ "$answer" == "y" || "$answer" == "Y" ]]; then reboot; fi
