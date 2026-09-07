# Intel integrated GPU: VA-API, OpenCL, kernel driver.
{ config, pkgs, lib, ... }:

lib.mkIf (config.hardware.pc.gpuVendor == "igpu_intel") {
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
    intel-compute-runtime
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
