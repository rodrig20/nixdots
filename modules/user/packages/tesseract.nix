# tesseract, OCR engine CLI.
{ config, pkgs, lib, ... }:

let
  cfg = config.userSettings.programs.tesseract;
in
{
  options.userSettings.programs.tesseract.enable = lib.mkEnableOption "tesseract OCR engine";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.tesseract.override { enableLanguages = [ "eng" "por" ]; })
    ];
  };
}
