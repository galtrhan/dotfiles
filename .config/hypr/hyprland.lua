local home = os.getenv("HOME")
package.path = home .. "/.config/hypr/?.lua;" .. package.path

local terminal = "ghostty"
local browser = "zen-browser"
local fileManager = "nautilus"
local menu = "qs ipc call launcher toggle"

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ADW_DISABLE_PORTAL", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("GBM_BACKEND", "i915")
hl.env("__GL_SHADER_DISK_CACHE", "1")
hl.env("__GL_SHADER_DISK_CACHE_PATH", "/tmp/shaders")
hl.env("__GL_SHADER_DISK_CACHE_SKIP_CLEANUP", "1")
hl.env("HYPRSHOT_DIR", home .. "/Pictures/Screenshots")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(home .. "/.config/hypr/scripts/wallpaper_restore.sh")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist -max-items 500 store")
    hl.exec_cmd("wl-paste --type image --watch cliphist -max-items 10 store")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd(home .. "/.config/hypr/scripts/kbd_monitor.sh start")
    hl.exec_cmd("signal-desktop --password-store=gnome-libsecret")
    hl.exec_cmd("enpass")
    hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets,pkcs11,ssh,gpg")
end)

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.workspace_rule({
    workspace = "special:terminal",
    on_created_empty = "ghostty -e tmux new-session -A -s \239\187\190",
})

hl.workspace_rule({
    workspace = "special:sudo",
})

hl.config({
    input = {
        kb_layout = "lv",
        kb_variant = "apostrophe",
        kb_model = "thinkpad",
        kb_options = "",
        kb_rules = "",
        repeat_rate = 50,
        repeat_delay = 300,
        follow_mouse = true,
        sensitivity = 0,
        numlock_by_default = true,
        force_no_accel = true,
        float_switch_override_focus = 2,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
            tap_to_click = true,
            drag_lock = true,
            scroll_factor = 1.0,
        },
    },
})

hl.device({
    name = "tpps2-ibm-trackpoint",
    sensitivity = -0.5,
    accel_profile = "flat",
})

hl.device({
    name = "synaptics-tm2964-001",
    sensitivity = 0.5,
    accel_profile = "flat",
})

hl.device({
    name = "logitech-m720-triathlon-multi-device-mouse-1",
    scroll_factor = 2,
})

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 6,
        border_size = 1,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "master",
    },
    decoration = {
        dim_special = 0.4,
        rounding = 4,
        active_opacity = 0.97,
        inactive_opacity = 0.8,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 4,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            vibrancy = 0.1696,
            special = false,
        },
    },
    animations = {
        enabled = false,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    misc = {
        disable_splash_rendering = true,
        disable_hyprland_logo = true,
        middle_click_paste = false,
    },
})

require("configs.keybinds")
require("configs.windowrules")
