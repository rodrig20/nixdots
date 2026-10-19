# Hydra Launcher: game launcher with an embedded BitTorrent client (native + Proton games).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.hydra;

  # Proton runs through umu, and the AppImage ships `umu-run` as a Python zipapp
  # (shebang `#!/usr/bin/env python3`, ~400 KB). Upstream runs it as
  # `python3 <umu-run> ...`, trying $HYDRA_UMU_PYTHON, then /usr/bin/python3,
  # then bare `python3`. On NixOS the first two are empty (there is no
  # /usr/bin/python3), so the spawn fails with a silent "Failed to spawn
  # umu-run". Pinning a known-good interpreter here removes the dependency on
  # the session PATH entirely.
  #
  # umu downloads its own runner (UMU-Proton) and the Steam Linux Runtime into
  # ~/.local/share/Steam on first use, so no Steam install is needed.
  hydra = pkgs.symlinkJoin {
    name = "hydralauncher-wrapped-${pkgs.hydralauncher.version}";
    paths = [ pkgs.hydralauncher ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      mv $out/bin/hydralauncher $out/bin/hydralauncher.real
      makeShellWrapper $out/bin/hydralauncher.real $out/bin/hydralauncher \
        --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]} \
        --set HYDRA_UMU_PYTHON ${lib.getExe pkgs.python3}

      # The upstream desktop entry points at the un-wrapped store path, so
      # launching from the app menu would skip the wrapper and lose the pinned
      # interpreter. Recreate it against our own $out.
      rm $out/share/applications/hydralauncher.desktop
      substitute ${pkgs.hydralauncher}/share/applications/hydralauncher.desktop \
        $out/share/applications/hydralauncher.desktop \
        --replace-fail "${pkgs.hydralauncher}/bin/hydralauncher" "$out/bin/hydralauncher"
    '';
  };
in
{
  options.userSettings.programs.hydra.enable = lib.mkEnableOption "Hydra Launcher";

  config = lib.mkIf cfg.enable {
    home.packages = [ hydra ];
  };
}