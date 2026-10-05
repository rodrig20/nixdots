hl.on("hyprland.start", function ()
    -- D-Bus
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("dbus-update-activation-environment --systemd GNOME_KEYRING_CONTROL GNOME_KEYRING_PID SSH_AUTH_SOCK")

    -- Load cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 28")

    -- Allow local root GUI apps on XWayland for the session.
    hl.exec_cmd("xhost +SI:localuser:root")

    -- Noctalia (systemd user service, supervised by the unit)
    hl.exec_cmd("systemctl --user start noctalia.service")

    -- Graphical session target: required by xdg-desktop-portal.service
    -- (Requisite). GDM doesn't activate it for Hyprland; the drop-in in
    -- modules/system/desktop/default.nix allows this manual start.
    hl.exec_cmd("systemctl --user start graphical-session.target")

    -- Restart portals so they catch the environment
    hl.exec_cmd("systemctl --user stop xdg-desktop-portal xdg-desktop-portal-hyprland")
    hl.exec_cmd("sleep 1 && systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal")

    -- Clipboard
    hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
end)
