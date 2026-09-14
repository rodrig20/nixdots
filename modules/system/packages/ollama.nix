# Ollama local LLM server.
{ config, pkgs, lib, ... }:

let
  cfg = config.systemSettings.ollama;

  # Vulkan + iGPU offload only makes sense with an Intel iGPU present.
  # Anything else ("other") gets the stock build with no forced backend,
  # so a CPU-only or dGPU host never gets pointless Vulkan/IGPU flags.
  isIntelIGpu = config.hardware.pc.gpuVendor == "igpu_intel";
in
{
  options.systemSettings.ollama.enable = lib.mkEnableOption "Ollama local LLM server";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;

      # Vulkan backend only on Intel iGPU (SYCL/oneAPI not packaged yet);
      # stock build elsewhere.
      package =
        if isIntelIGpu then
          pkgs.ollama-vulkan
        else
          pkgs.ollama;

      host = "127.0.0.1";
      port = 11434;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "30m";
      }
      // lib.optionalAttrs isIntelIGpu {
        OLLAMA_VULKAN = "1";
        OLLAMA_IGPU_ENABLE = "1";
      };
    };
  };
}
