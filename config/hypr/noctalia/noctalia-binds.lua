-- Noctalia shell core binds (launcher, clipboard, session, media keys, ...).
-- Loaded only when userSettings.noctalia.enable is true (see
-- modules/user/packages/hyprland.nix). Plugin-specific binds live in
-- noctalia-plugins/.
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Settings & Panels
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("noctalia msg settings-toggle"), { description = "Toggle noctalia-settings" })
hl.bind(mainMod .. " + Comma", hl.dsp.exec_cmd("noctalia msg settings-toggle"), { description = "Toggle noctalia-settings" })
hl.bind(mainMod .. " + Period", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher \"/e \""), { description = "Open the emoji picker" })
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("noctalia msg panel-toggle notifiactions"), { description = "Open Notifications" })

-- Screenshots
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen"), { description = "Take fullscreen screenshot" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("noctalia msg screenshot-region"), { description = "Take screenshot of region" })
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("noctalia msg screenshot-annotate"), { description = "Take screenshot with annotations" })

-- Wallpaper
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"), { description = "Open wallpaper selector" })
hl.bind(mainMod .. " + SHIFT + ALT + W", hl.dsp.exec_cmd("noctalia msg wallpaper-random"), { description = "Change to a random wallpaper" })

-- Launcher, Bar, Clipboard, Control Center
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "Open application launcher" })
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd("noctalia msg bar-toggle"), { description = "Toggle status bar" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"), { description = "Open clipboard manager" })
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("noctalia msg clipboard-clear"), { description = "Clear clipboard" })
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"), { description = "Toggle control center" })
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"), { description = "Toggle notifications" })

-- Session & Lock
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "Toggle session control-center" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("noctalia msg session lock"), { description = "Lock screen" })
hl.bind(mainMod .. " + SHIFT + ALT + L", hl.dsp.exec_cmd("noctalia msg session lock-and-suspend"), { description = "Lock screen and suspend" })

-- Desktop Widgets
hl.bind(mainMod .. " + SHIFT + ALT + G", hl.dsp.exec_cmd("noctalia msg desktop-widgets-toggle-edit"), { description = "Toggle desktop widgtes edit" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("noctalia msg desktop-widgets-toggle"), { description = "Toggle desktop widgtes edit" })

-- Media Keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("noctalia msg volume-up"),       { locked = true, repeating = true, description = "Raise volume" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("noctalia msg volume-down"),     { locked = true, repeating = true, description = "Lower volume" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("noctalia msg volume-mute"),     { locked = true, repeating = true, description = "Mute audio" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("noctalia msg mic-mute"),        { locked = true, repeating = true, description = "Mute microphone" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("noctalia msg brightness-up"),   { locked = true, repeating = true, description = "Increase brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("noctalia msg brightness-down"), { locked = true, repeating = true, description = "Decrease brightness" })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("noctalia msg media next"),       { locked = true, description = "Next track" })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("noctalia msg media toggle"),     { locked = true, description = "Toggle media playback" })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("noctalia msg media toggle"),     { locked = true, description = "Toggle media playback" })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("noctalia msg media previous"),   { locked = true, description = "Previous track" })
