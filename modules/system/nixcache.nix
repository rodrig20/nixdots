# Self-hosted binary cache: serves the NARs published to GHCR as a substituter.
# Publishing happens in CI (publish-cache.yml); this module only runs the local
# proxy on localhost:37515, so rebuilds substitute our own paths instead of
# recompiling them. Signing: private half in the NIX_SIGNING_KEY secret, public
# half in flake.nix nixConfig (trusted by modules/system/nix, not repeated here).
{ config, lib, inputs, ... }:

let
  cfg = config.systemSettings.nixcache;
in
{
  options.systemSettings.nixcache.enable = lib.mkEnableOption
    "nixcache-proxy (local substituter for the GHCR binary cache)";

  # Imports cannot be conditional, so the module is always imported and only
  # activates when services.nixcache-proxy is enabled below.
  imports = [ inputs.nixcache-oci.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.nixcache-proxy = {
      enable = true;
      repo = "rodrig20/nixdots";

      # publicKey stays at the upstream "" default on purpose: the key is
      # already in flake.nix nixConfig.extra-trusted-public-keys (applied by
      # modules/system/nix), which keeps a single definition; requireSignatures
      # keeps its default of true.
    };
  };
}
