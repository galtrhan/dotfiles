
# Rootless Docker
set -x DOCKER_HOST unix://$XDG_RUNTIME_DIR/docker.sock

# uv
fish_add_path "/home/galtrhan/.local/bin"
fish_add_path /home/galtrhan/fvm/default/bin
set -x ANDROID_SDK_ROOT /opt/android-sdk

# usagi
fish_add_path /home/galtrhan/.usagi/bin

set -x SUDO_ASKPASS ~/.config/hypr/scripts/sudo_askpass.sh
function sudo --wraps sudo
    if not isatty stdin; and set -q SUDO_ASKPASS
        command sudo -A $argv
    else
        command sudo $argv
    end
end
