-- Noctalia region-recorder plugin binds.
-- Loaded only when the regionRecorder plugin is enabled (see
-- modules/user/packages/hyprland.nix).
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("sh -c 'pgrep -x wl-screenrec >/dev/null && noctalia msg plugin h-jangra/region-recorder:service all stop || noctalia msg plugin h-jangra/region-recorder:service all record-fullscreen'"), { description = "Toggle fullscreen recording" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("sh -c 'pgrep -x wl-screenrec >/dev/null && noctalia msg plugin h-jangra/region-recorder:service all stop || noctalia msg plugin h-jangra/region-recorder:service all select-region'"), { description = "Toggle region recording" })
