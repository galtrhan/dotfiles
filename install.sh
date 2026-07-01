#!/bin/bash

# List of packages to install
pacman_packages=(
	yay
	stow
	fish
	docker
	docker-compose
	docker-buildx
	rootlesskit
	slirp4netns
	hyprland
	hyprcursor
	hypridle
	hyprlock
	hyprpaper
	hyprshot
	waybar
	quickshell
	nautilus
	networkmanager
	network-manager-applet
	blueman
	cliphist
	ttf-jetbrains-mono-nerd
	tmux
	neovim
	yazi
	ghostty
	wf-recorder
	slurp
	wl-clipboard
	ffmpeg
	libnotify
	brightnessctl
	gnome-keyring
	gparted
	gedit
	imv
)

yay_packages=(
	hyprpolkitagent-git
	shmooz
)

configs_to_remove=(
	fish
	hypr
	nvim
	tmux
	waybar
	ghostty
	quickshell
	systemd
)

# Check if sudo is available for root permissions, maybe not needed
if ! command -v sudo >/dev/null 2>&1; then
	echo "Error: sudo is not installed. Please install sudo first."
	exit 1
fi

# Check if pacman is available
if ! command -v pacman >/dev/null 2>&1; then
	echo "Error: pacman is not installed or not in PATH."
	exit 1
fi


# Update the package database
echo "Updating package database..."
sudo pacman -Syu --noconfirm

# Install repository packages (skip already up-to-date packages)
echo "Installing pacman packages (only missing/newer)..."
sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"

# Install AUR packages (skip already up-to-date packages)
if command -v yay >/dev/null 2>&1; then
	echo "Installing AUR packages (only missing/newer)..."
	yay -S --needed --noconfirm "${yay_packages[@]}"
else
	echo "Warning: yay is not available, skipping AUR package installation."
fi

# Remove default configs
for config in "${configs_to_remove[@]}"; do
	echo "Removing $config config..."
	rm -rf "$HOME/.config/$config"
done

# Activate dotfiles
echo "Setting up .dotfiles..."
echo "Initializing git submodules (tmux plugins)..."
git -C "$HOME/.dotfiles" submodule update --init --recursive

echo "Installing udev rules for audio mute LEDs..."
DOTFILES_USER="$(id -un)"
DOTFILES_GROUP="$(id -gn)"
UDEV_TEMPLATE="$HOME/.dotfiles/.config/hypr/udev/90-audio-leds.rules"
UDEV_RENDERED="$(mktemp)"
sed "s/__DOTFILES_USER__/$DOTFILES_USER/g; s/__DOTFILES_GROUP__/$DOTFILES_GROUP/g" "$UDEV_TEMPLATE" > "$UDEV_RENDERED"
sudo install -m 0644 "$UDEV_RENDERED" /etc/udev/rules.d/90-audio-leds.rules
rm -f "$UDEV_RENDERED"
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=leds

chmod +x ~/.dotfiles/.config/hypr/scripts/*.sh
chmod +x ~/.dotfiles/.local/bin/*
stow .

# Disable dunst if previously installed (QuickShell handles notifications)
if systemctl --user is-enabled dunst.service &>/dev/null; then
	echo "Disabling dunst (QuickShell handles notifications)..."
	systemctl --user disable --now dunst.service 2>/dev/null || true
	systemctl --user mask dunst.service 2>/dev/null || true
fi

# Enable & start bluetooth service
echo "Enabling & starting bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

echo "Installation complete."
