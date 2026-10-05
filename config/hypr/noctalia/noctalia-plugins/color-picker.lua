-- Noctalia color_picker plugin binds.
-- Loaded only when the colorPicker plugin is enabled (see
-- modules/user/packages/hyprland.nix).
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("noctalia msg plugin oldirtty/color_picker:service all pick"), { description = "Open the color picker" })
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("noctalia msg panel-toggle oldirtty/color_picker:panel"), { description = "Open the color picker panel" })
