#!/bin/sh

# List of packages to install
pacman_packages=(
	yay
	stow
	fish
	hyprland
	hyprcursor
	hypridle
	hyprlock
	hyprpaper
	hyprshot
	waybar
	rofi
	dunst
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
)

yay_packages=(
	hyprpolkitagent-git
)

configs_to_remove=(
	fish
	hypr
	nvim
	tmux
	waybar
	ghostty
	dunst
	rofi
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

# Install each package
for package in "${pacman_packages[@]}"; do
	echo "Installing $package..."
	sudo pacman -S --noconfirm "$package"
done

# Remove default configs
for config in "${configs_to_remove[@]}"; do
	echo "Removing $config config..."
	rm -rf "$HOME/.config/$config"
done

# Activate dotfiles
echo "Setting up .dotfiles..."
chmod +x ~/.dotfiles/.config/hypr/scripts/*.sh
stow .

# Enable & start bluetooth service
echo "Enabling & starting bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

echo "Installation complete."
