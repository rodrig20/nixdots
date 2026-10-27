# Newelle GTK4 AI assistant (Ollama + OpenRouter + vision).
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.newelle;

  # Upstream package.nix passes "\${gappsWrapperArgs[@]}" as a literal string
  # and multi-word "--prefix PATH : ..." strings in makeWrapperArgs, which
  # makeCWrapper rejects. Word-split the args and expand the array in
  # preFixup (nixpkgs manual pattern).
  fixedNewelle = pkgs.newelle.overrideAttrs (old: {
    makeWrapperArgs = lib.flatten (
      map (lib.splitString " ") (
        lib.remove "\${gappsWrapperArgs[@]}" (old.makeWrapperArgs or [ ])
      )
    );
    preFixup = (old.preFixup or "") + ''
      makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
    '';
  });
in
{
  options.userSettings.programs.newelle.enable = lib.mkEnableOption "Newelle AI assistant";

  config = lib.mkIf cfg.enable {
    home.packages = [ fixedNewelle ];
  };
}
