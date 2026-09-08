hl.on("hyprland.start", function ()
    -- D-Bus
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("dbus-update-activation-environment --systemd GNOME_KEYRING_CONTROL GNOME_KEYRING_PID SSH_AUTH_SOCK")

    -- Load cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 28")

    -- Noctalia (systemd user service, supervised by the unit)
    hl.exec_cmd("systemctl --user start noctalia.service")

    -- Restart portals so they catch the environment
    hl.exec_cmd("systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 1 && systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")

    -- Clipboard
    hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
end)
