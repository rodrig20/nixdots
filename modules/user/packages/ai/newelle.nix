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

  # OpenRouter key from the same agenix secret used by opencode (decrypted at activation).
  openrouterSecretKey = lib.optionalAttrs (
    config ? age && config.age ? secrets && builtins.hasAttr "openrouter-api-key" config.age.secrets
  ) {
    value = builtins.readFile config.age.secrets.openrouter-api-key.path;
  };
in
{
  options.userSettings.programs.newelle.enable = lib.mkEnableOption "Newelle AI assistant";

  config = lib.mkIf cfg.enable {
    home.packages = [ fixedNewelle ];

    # OpenRouter key shared with opencode, from agenix secret.
    home.sessionVariables = lib.optionalAttrs (
      cfg.enable && openrouterSecretKey ? null && openrouterSecretKey.value != null
    ) {
      OPENROUTER_API_KEY = openrouterSecretKey.value;
    };
  };
}
