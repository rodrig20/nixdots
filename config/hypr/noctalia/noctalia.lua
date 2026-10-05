-- Noctalia shell integration: service autostart and layer rules.
-- Loaded only when userSettings.noctalia.enable is true (see
-- modules/user/packages/hyprland.nix).

hl.on("hyprland.start", function ()
    -- Noctalia (systemd user service, supervised by the unit)
    hl.exec_cmd("systemctl --user start noctalia.service")
end)

hl.layer_rule({
  name = "noctalia",
  match = {
    namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
  },
  no_anim = true,
  ignore_alpha = 0.5,
  blur = true,
  blur_popups = true,
})
