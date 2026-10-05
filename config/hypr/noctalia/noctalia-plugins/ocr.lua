-- OCR keybind through the fel/ocr plugin (languages from plugin_settings).
-- Loaded only when the ocr plugin is enabled (see
-- modules/user/packages/hyprland.nix).
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("noctalia msg plugin fel/ocr:ocr all ocr-region"), { description = "OCR selected region to clipboard" })
