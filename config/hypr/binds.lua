-- Configuration
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local workspaceGroupSize = 10
local battery_saver = false

function layout_bind(default_action, overrides)
    return function()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then return end

        local layout = workspace.tiled_layout

        if overrides and overrides[layout] then
            hl.dispatch(overrides[layout])
        elseif default_action then 
            hl.dispatch(default_action)
        end
    end
end

-- Applications
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"), { description = "Open the terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"), { description = "Open the browser" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"), { description = "Open the filemanager" })

function workspace_in_group(i)
    local curr = hl.get_active_workspace().id
    local newVal = math.floor((curr - 1) / workspaceGroupSize) * workspaceGroupSize + i
    return newVal
end

-- Workspaces Navigation & Management
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           function() hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) })) end, { description = "Focus workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key,   function() hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false })) end, { description = "Move window to workspace " .. i })
end

hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ workspace = "e+1" }), { description = "Switch to next workspace" })
hl.bind(mainMod .. " + ALT + left",  hl.dsp.focus({ workspace = "e-1" }), { description = "Switch to previous workspace" })
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.window.move({ workspace = "e+1" }), { description = "Move window to next workspace" })
hl.bind(mainMod .. " + SHIFT + ALT + left",  hl.dsp.window.move({ workspace = "e-1" }), { description = "Move window to previous workspace" })

-- Window Focus & Layout-Aware Switching
hl.bind(mainMod .. " + left",  layout_bind(hl.dsp.focus({ direction = "left" }),  { monocle = hl.dsp.layout("cycleprev"), scrolling = hl.dsp.layout("focus l")}), { description = "Move focus left" })
hl.bind(mainMod .. " + right", layout_bind(hl.dsp.focus({ direction = "right" }), { monocle = hl.dsp.layout("cyclenext"), scrolling = hl.dsp.layout("focus r")}), { description = "Move focus right" })
hl.bind(mainMod .. " + up",    layout_bind(hl.dsp.focus({ direction = "up" }),    { monocle = hl.dsp.layout("cyclenext") }), { description = "Move focus up" })
hl.bind(mainMod .. " + down",  layout_bind(hl.dsp.focus({ direction = "down" }),  { monocle = hl.dsp.layout("cycleprev") }), { description = "Move focus down" })

-- Window Swapping & Manipulation
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }), { description = "Swap window left" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }), { description = "Swap window right" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }), { description = "Swap window up" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }), { description = "Swap window down" })

-- Window Sizing & States
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = false }, { description = "Increase window width" })
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = false }, { description = "Reduce window width" })
hl.bind(mainMod .. " + CTRL + up",  hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = false }, { description = "Increase window height" })
hl.bind(mainMod .. " + CTRL + down",    hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = false }, { description = "Reduce window height" })


hl.bind(mainMod .. " + ALT + down", layout_bind(nil, { scrolling = hl.dsp.layout("colresize -conf"), { repeating = false } }), { description = "Increase window height" })
hl.bind(mainMod .. " + ALT + up",   layout_bind(nil, { scrolling = hl.dsp.layout("colresize +conf"), { repeating = false } }), { description = "Reduce window height" })


hl.bind(mainMod .. " + Dead_Acute", layout_bind(nil, {scrolling = hl.dsp.layout("move +200")}), { repeating = true, description = "Move window left in scrolling layout" })
hl.bind(mainMod .. " + Dead_Tilde", layout_bind(nil, {scrolling = hl.dsp.layout("move -200")}), { repeating = true, description = "Move window right in scrolling layout" })

hl.bind(mainMod .. " + W", hl.dsp.window.close(), { description = "Kill active window" })
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"), { description = "Force kill active application" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Toggle maximize window" })
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Toggle fullscreen" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
hl.bind(mainMod .. " + ALT + T", function() hl.dispatch(hl.dsp.window.float({ action = "toggle" })); hl.dispatch(hl.dsp.window.pin()) end, { description = "Toggle floating and pinned" })
hl.bind(mainMod .. " + P", function() hl.dispatch(hl.dsp.window.float({ action = "toggle" })); hl.dispatch(hl.dsp.window.pin()) end, { description = "Toggle floating and pinned" })

-- Layout Splits & Groups
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(mainMod .. " + O", layout_bind(nil,{ dwindle = hl.dsp.layout("togglesplit")}), { description = "Toggle layout split direction" })
hl.bind(mainMod .. " + ALT + O", layout_bind(nil,{ dwindle = hl.dsp.layout("swapsplit")}), { description = "Swap layout split orientation" })
hl.bind(mainMod .. " + Z", layout_bind(nil,{ scrolling = hl.dsp.layout("swapcol l")}), { description = "Expel if not alone, consume if alone in previous column" })
hl.bind(mainMod .. " + X", layout_bind(nil,{ scrolling = hl.dsp.layout("swapcol r")}), { description = "Expel if not alone, consume if alone in next column" })
-- hl.bind(mainMod .. " + C", layout_bind(nil,{ scrolling = hl.dsp.layout("fit_into_view")}), { description = "Fits the currently active column fully into view" })
hl.bind(mainMod .. " + SHIFT + Z", layout_bind(nil,{ scrolling = hl.dsp.layout("consume_or_expel prev")}), { description = "Expel if not alone, consume if alone in previous column" })
hl.bind(mainMod .. " + SHIFT + X", layout_bind(nil,{ scrolling = hl.dsp.layout("consume_or_expel next")}), { description = "Expel if not alone, consume if alone in next column" })

-- Actions & System Controls
hl.bind(mainMod .. " + CTRL + SHIFT + H", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload Hyprland configuration" })

hl.bind(mainMod .. " + SHIFT + A", function()
    battery_saver = not battery_saver
    if battery_saver then
        hl.config({
            animations = { enabled = false },
            decoration = {
                active_opacity = 1,
                inactive_opacity = 1,
                fullscreen_opacity = 1,
                blur = { enabled = false },
                shadow = { enabled = false }
            }
        })
    else
        hl.config({
            animations = { enabled = true },
            decoration = {
                active_opacity = 0.8,
                inactive_opacity = 0.6,
                fullscreen_opacity = 0.8,
                blur = { enabled = true },
                shadow = { enabled = true }
            }
        })
    end
end, { description = "Toggle desktop widgtes edit" })

-- Special Workspace (Scratchpad)
hl.bind(mainMod .. " + Backslash",         hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle special workspace" })
hl.bind(mainMod .. " + SHIFT + Backslash", function() hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })) end, { description = "Toggle window in/out of special workspace" })

-- Mouse Bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Move window with mouse" })
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.resize(),   { mouse = true, description = "Resize window with mouse" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window with mouse" })

-- Workspace Layout Strategy
function set_layout(new_layout)
    return function ()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then return end

        if workspace.special then
            hl.workspace_rule({ workspace = tostring(workspace.name), layout = new_layout })
        else
            hl.workspace_rule({ workspace = tostring(workspace.id), layout = new_layout })
        end
    end
end

hl.bind(mainMod .. " + SHIFT + Comma", set_layout("dwindle"), { description = "Set layout to dwindle" })
hl.bind(mainMod .. " + SHIFT + Period", set_layout("scrolling"), { description = "Set layout to scrolling" })
hl.bind(mainMod .. " + SHIFT + Minus", set_layout("monocle"), { description = "Set layout to monocle" })
