#
# ~/.bashrc
#

export ANDROID_HOME=/opt/android-sdk
export ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_NDK_HOME=/opt/android-sdk/ndk/28.2.13676358

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/share/fvm/default/bin:$PATH"
export PATH="$HOME/.usagi/bin:$PATH"
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
export NODE_COMPILE_CACHE=/tmp/node-compile-cache
export GOPATH="$HOME/.local/share/go"
export PATH="$GOPATH/bin:$PATH"
alias agent='cursor-agent'
alias vi='nvim'
export EDITOR=nvim
export VISUAL=nvim
export MD2PDF_CHROME="$HOME/.local/bin/chromium"
export CARGO_BUILD_JOBS=4
