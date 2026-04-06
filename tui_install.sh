#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ◈ Dotfiles Installer (TUI Edition)
# ------------------------------------------------------------------------------

set -e

# Colors for terminal output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. TUI - Gather Information
# ------------------------------------------------------------------------------

# Driver Selection
if [[ -z "$DRIVER_CHOICE" ]]; then
    DRIVER_CHOICE=$(whiptail --title "Driver Selection" --menu "Which GPU drivers do you need?" 15 60 4 \
    "AMD" "Vulkan-Radeon, Mesa (Recommended for you)" \
    "NVIDIA" "Proprietary NVIDIA drivers" \
    "Intel" "Vulkan-Intel, Mesa" \
    "None" "Skip driver installation" 3>&1 1>&2 2>&3)
fi

# Keyboard Layout
if [[ -z "$KB_LAYOUT" ]]; then
    KB_LAYOUT=$(whiptail --title "Keyboard Layout" --inputbox "Enter your keyboard layout (e.g., us, gb, fr, de):" 10 60 "us" 3>&1 1>&2 2>&3)
fi

# City / Timezone
if [[ -z "$CITY_TIMEZONE" ]]; then
    CITY_TIMEZONE=$(whiptail --title "Timezone" --inputbox "Enter your Region/City (e.g., Africa/Lagos, Europe/London, America/New_York):" 10 60 "Africa/Lagos" 3>&1 1>&2 2>&3)
fi

# Confirm Proceed (Skip if headless)
if [[ -z "$HEADLESS" ]]; then
    if ! whiptail --title "Proceed?" --yesno "Ready to begin installation with these settings?\n\nDrivers: $DRIVER_CHOICE\nLayout: $KB_LAYOUT\nTimezone: $CITY_TIMEZONE" 12 60; then
        echo -e "${RED}Installation cancelled by user.${NC}"
        exit 0
    fi
fi

# 2. System Detection
# ------------------------------------------------------------------------------
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Error: Could not detect OS.${NC}"
    exit 1
fi

echo -e "${BLUE}◈ Detected OS: $OS${NC}"

# 3. Package Management
# ------------------------------------------------------------------------------

# Base Packages
ARCH_PKGS=(hyprland hypridle hyprlock stow git github-cli rofi-wayland swaync kitty brave-browser steam lutris gamemode lib32-gamemode mangohud lib32-mangohud noto-fonts-cjk noto-fonts-emoji ttf-font-awesome noto-fonts ttf-jetbrains-mono ttf-jetbrains-mono-nerd python-pip python-requests)
FEDORA_PKGS=(hyprland stow git gh rofi-wayland swaync kitty steam lutris gamemode mangohud google-noto-cjk-fonts fontawesome-fonts jetbrains-mono-fonts python3-pip)
DEBIAN_PKGS=(stow git gh kitty steam lutris gamemode mangohud fonts-noto-cjk fonts-font-awesome fonts-jetbrains-mono python3-pip python3-requests)

# Add Drivers to package lists
case $DRIVER_CHOICE in
    AMD)
        if ! pacman -Qi mesa-tkg-git &>/dev/null; then
            ARCH_PKGS+=(vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa)
        else
            echo -e "${BLUE}Detected mesa-tkg-git, skipping potentially conflicting Vulkan packages...${NC}"
        fi
        FEDORA_PKGS+=(mesa-dri-drivers)
        DEBIAN_PKGS+=(mesa-vulkan-drivers)
        ;;
    NVIDIA)
        ARCH_PKGS+=(nvidia nvidia-utils lib32-nvidia-utils nvidia-settings)
        FEDORA_PKGS+=(akmod-nvidia xorg-x11-drv-nvidia-cuda)
        DEBIAN_PKGS+=(nvidia-driver)
        ;;
    Intel)
        ARCH_PKGS+=(vulkan-intel lib32-vulkan-intel mesa lib32-mesa)
        FEDORA_PKGS+=(mesa-dri-drivers)
        DEBIAN_PKGS+=(mesa-vulkan-drivers)
        ;;
esac

# 4. Installation Logic
# ------------------------------------------------------------------------------
case $OS in
    arch|cachyos)
        sudo pacman -Syu --noconfirm
        sudo pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"
        if ! command -v yay &> /dev/null; then
            git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm && cd -
        fi
        # Check for Quickshell
        QS_PKG="quickshell-git"
        if pacman -Qi quickshell &>/dev/null || pacman -Qi quickshell-git &>/dev/null; then
            echo -e "${BLUE}Quickshell already installed, skipping...${NC}"
            QS_PKG=""
        fi
        
        yay -S --noconfirm $QS_PKG matugen-bin catppuccin-gtk-theme-mocha dracula-gtk-theme rose-pine-gtk-theme gruvbox-gtk-theme-git nordic-theme
        ;;
    fedora)
        sudo dnf update -y
        sudo dnf install -y "${FEDORA_PKGS[@]}"
        if ! command -v matugen &> /dev/null; then
            curl -L https://github.com/InioS/matugen/releases/latest/download/matugen-linux-x86_64 -o /tmp/matugen
            sudo install -m 755 /tmp/matugen /usr/local/bin/matugen
        fi
        ;;
    debian|ubuntu)
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y "${DEBIAN_PKGS[@]}"
        ;;
esac

# 5. Apply User Preferences (Timezone & Keyboard)
# ------------------------------------------------------------------------------
echo -e "${BLUE}◈ Applying System Preferences...${NC}"

# Timezone
if timedatectl list-timezones | grep -q "^$CITY_TIMEZONE$"; then
    sudo timedatectl set-timezone "$CITY_TIMEZONE"
    echo -e "${GREEN}Timezone set to $CITY_TIMEZONE${NC}"
else
    echo -e "${YELLOW}Warning: Invalid timezone $CITY_TIMEZONE. Skipping.${NC}"
fi

# Keyboard Layout (System-wide)
sudo localectl set-x11-keymap "$KB_LAYOUT"
echo -e "${GREEN}System keyboard layout set to $KB_LAYOUT${NC}"

# 6. Setup Dotfiles
# ------------------------------------------------------------------------------
echo -e "${BLUE}◈ Setting up Stow links...${NC}"
DOT_DIR="$HOME/dotfiles"

cd "$DOT_DIR/config"
for pkg in *; do stow -v -R -t ~ "$pkg"; done

cd "$DOT_DIR/home"
for pkg in *; do stow -v -R -t ~ "$pkg"; done

# Update Hyprland config with selected layout
HYPR_ENV="$HOME/.config/hypr/modules/env.conf"
if [ -f "$HYPR_ENV" ]; then
    sed -i "s/kb_layout = .*/kb_layout = $KB_LAYOUT/" "$HYPR_ENV" || echo "device:kb_layout = $KB_LAYOUT" >> "$HYPR_ENV"
fi

# 7. Finalize
# ------------------------------------------------------------------------------
mkdir -p ~/.config
echo "--gtk-version=4 --enable-features=TouchpadOverscrollHistoryNavigation --enable-wayland-ime --ozone-platform-hint=auto" > ~/.config/brave-flags.conf

echo -e "${GREEN}◈ Installation Complete!${NC}"
echo -e "${BLUE}Please restart your session.${NC}"
