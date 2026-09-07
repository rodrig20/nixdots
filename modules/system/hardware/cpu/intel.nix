# Intel CPU: thermald.
{ config, pkgs, lib, ... }:

lib.mkIf (config.hardware.pc.cpuVendor == "intel") {
  services.thermald.enable = true;
}
