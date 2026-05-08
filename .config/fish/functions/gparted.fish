function gparted
    pkexec env WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR GDK_BACKEND=wayland gparted $argv
end
