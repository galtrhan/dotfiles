local home = os.getenv("HOME")
local terminal = "ghostty"
local browser = "zen-browser"
local fileManager = "nautilus"
local menu = "qs ipc call launcher toggle"
local mainMod = "SUPER"

hl.bind(mainMod .. " + BACKSPACE", hl.dsp.exit())
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + C", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock --grace 0"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/power.sh"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("bash -c 'SELECTED=$(cliphist list | " .. home .. "/.config/hypr/scripts/qs-menu.sh Clipboard); [ -n \"$SELECTED\" ] && echo \"$SELECTED\" | cliphist decode | wl-copy'"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs ipc call launcher emoji_toggle"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("pkill -x quickshell; quickshell &"))

hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screen_capture_menu.sh"))

hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/wallpaper_control.sh change"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("pkill quickshell || quickshell"))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + BACKSLASH", hl.dsp.workspace.toggle_special("terminal"))
hl.bind(mainMod .. " + SHIFT + BACKSLASH", hl.dsp.window.move({ workspace = "special:terminal" }))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh --toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/brightness.sh down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region"))

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle_solo.sh"))

hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications center_toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call notifications dnd_toggle"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("qs ipc call notifications dismiss_all"))

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("qs ipc call bar toggle"))

hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("shmooz"))
