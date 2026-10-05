-- Noctalia wl-screen-mirror plugin binds.
-- Loaded only when the mirror plugin is enabled (see
-- modules/user/packages/hyprland.nix).
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("noctalia msg panel-toggle elijaharch/wl-screen-mirror:controls"), { description = "Open the screen mirror panel" })
