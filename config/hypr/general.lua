local colors = require("colors")

hl.config({
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },
	 general = {
        gaps_in  = 10,
        gaps_out = 15,
        border_size = 3,

        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },

        resize_on_border = true,
        allow_tearing = false,
        no_focus_fallback = true,
        layout = "dwindle",
        
        snap = {
             enabled = true,
             window_gap = 4,
             monitor_gap = 5,
             respect_gaps = true
         }
        
    },
    group = {
    	groupbar = {
    		font_size = 12,
    		font_weight_active = "bold",
    		height = 20,
    	},
    },
    decoration = {
        rounding = 10,
        active_opacity = 0.9,
        inactive_opacity = 0.6,
        fullscreen_opacity = 1.0,

        blur = {
            enabled = true,
            size = 3,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = true,
        },

        shadow = {
            enabled = true,
            range = 20,
            render_power = 10,
            offset = {0, 2},
            color = "0x66000000",
        },
        dim_inactive = true,
		dim_strength = 0.1,
        dim_special = 0.2
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        enable_swallow = false,
        swallow_regex = "(foot|kitty|allacritty|Alacritty|ghostty)",
        on_focus_under_fullscreen = 2,
        allow_session_lock_restore = true,
        session_lock_xray = true,
        initial_workspace_tracking = false,
        focus_on_activate = true
    },

    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        zoom_disable_aa = true,
        hotspot_padding = 1
    },

    xwayland = {
        force_zero_scaling = true
    }
})


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

hl.window_rule({
  match = { fullscreen = true },
  no_blur = true,
  opaque = true,
})

hl.workspace_rule({ workspace = "f[1]", gaps_out = 5, no_border = true})
hl.workspace_rule({ workspace = "s[true]", gaps_out = 50 })
hl.workspace_rule({ workspace = "s[true]f[1]", gaps_out = 15 })


for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.workspace_rule({ workspace = key, persistent = true})
end

