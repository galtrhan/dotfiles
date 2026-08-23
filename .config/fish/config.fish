
# Rootless Docker
set -x DOCKER_HOST unix://$XDG_RUNTIME_DIR/docker.sock

# uv
fish_add_path "/home/galtrhan/.local/bin"
fish_add_path "/home/galtrhan/.local/share/fvm/default/bin"
set -gx GOPATH "$HOME/.local/share/go"
fish_add_path "$GOPATH/bin"
set -x ANDROID_SDK_ROOT /opt/android-sdk

# usagi
fish_add_path /home/galtrhan/.usagi/bin

set -x NODE_COMPILE_CACHE /tmp/node-compile-cache
# Keep temporary profiles created by Node tools (including Lighthouse) out of $HOME.
set -gx TMPDIR /tmp
set -x SUDO_ASKPASS ~/.config/hypr/scripts/sudo_askpass.sh
function sudo --wraps sudo
    if not isatty stdin; and set -q SUDO_ASKPASS
        command sudo -A $argv
    else
        command sudo $argv
    end
end

alias agent='cursor-agent'
