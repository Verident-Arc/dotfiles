#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ◈ Dotfiles Installer
# ------------------------------------------------------------------------------
# Supports: Arch Linux, Fedora, Debian/Ubuntu
# ------------------------------------------------------------------------------

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}◈ Starting Dotfiles Installation...${NC}"

# 1. Detect Distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Error: Could not detect OS.${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS: $OS${NC}"

# 2. Package Lists
ARCH_PKGS=(
    hyprland hypridle hyprlock stow git github-cli 
    rofi-wayland swaync kitty brave-browser
    steam lutris gamemode lib32-gamemode mangohud lib32-mangohud
    vulkan-radeon lib32-vulkan-radeon noto-fonts-cjk noto-fonts-emoji 
    ttf-font-awesome noto-fonts ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    python-pip python-requests
)

FEDORA_PKGS=(
    hyprland stow git gh rofi-wayland swaync kitty 
    steam lutris gamemode mangohud google-noto-cjk-fonts 
    fontawesome-fonts jetbrains-mono-fonts python3-pip
)

DEBIAN_PKGS=(
    stow git gh kitty steam lutris gamemode mangohud
    fonts-noto-cjk fonts-font-awesome fonts-jetbrains-mono
    python3-pip python3-requests
)

# 3. Installation Logic
case $OS in
    arch|cachyos)
        echo -e "${YELLOW}Updating Arch...${NC}"
        sudo pacman -Syu --noconfirm
        echo -e "${YELLOW}Installing packages...${NC}"
        sudo pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"
        
        # AUR Helper (Yay)
        if ! command -v yay &> /dev/null; then
            echo -e "${YELLOW}Installing Yay...${NC}"
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            cd /tmp/yay && makepkg -si --noconfirm
            cd -
        fi
        
        echo -e "${YELLOW}Installing AUR packages (quickshell, matugen, themes)...${NC}"
        yay -S --noconfirm quickshell-git matugen-bin catppuccin-gtk-theme-mocha dracula-gtk-theme rose-pine-gtk-theme gruvbox-gtk-theme-git nordic-theme
        ;;

    fedora)
        echo -e "${YELLOW}Updating Fedora...${NC}"
        sudo dnf update -y
        echo -e "${YELLOW}Installing packages...${NC}"
        sudo dnf install -y "${FEDORA_PKGS[@]}"
        
        # Matugen (Binary install for Fedora as it might not be in repos)
        if ! command -v matugen &> /dev/null; then
            echo -e "${YELLOW}Downloading Matugen binary...${NC}"
            curl -L https://github.com/InioS/matugen/releases/latest/download/matugen-linux-x86_64 -o /tmp/matugen
            sudo install -m 755 /tmp/matugen /usr/local/bin/matugen
        fi
        ;;

    debian|ubuntu)
        echo -e "${YELLOW}Updating Debian/Ubuntu...${NC}"
        sudo apt update && sudo apt upgrade -y
        echo -e "${YELLOW}Installing packages...${NC}"
        sudo apt install -y "${DEBIAN_PKGS[@]}"
        
        echo -e "${RED}Note: Hyprland and Quickshell often require manual compilation or 3rd party repos on Debian/Ubuntu.${NC}"
        ;;

    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

# 4. Setup Dotfiles
echo -e "${BLUE}◈ Setting up Stow links...${NC}"
DOT_DIR="$HOME/dotfiles"

if [ ! -d "$DOT_DIR" ]; then
    echo -e "${RED}Error: $DOT_DIR not found.${NC}"
    exit 1
fi

cd "$DOT_DIR/config"
for pkg in *; do
    echo -e "${YELLOW}Stowing config: $pkg${NC}"
    # Use --adopt to merge existing files, followed by git checkout to keep repo version
    stow -v --adopt -t ~ "$pkg"
done

cd "$DOT_DIR/home"
for pkg in *; do
    echo -e "${YELLOW}Stowing home: $pkg${NC}"
    stow -v --adopt -t ~ "$pkg"
done

# Reset any changes stow --adopt might have made to the repo files
cd "$DOT_DIR"
git checkout .

# 5. Brave Flags
echo -e "${BLUE}◈ Setting up Brave flags...${NC}"
mkdir -p ~/.config
echo "--gtk-version=4 --enable-features=TouchpadOverscrollHistoryNavigation --enable-wayland-ime --ozone-platform-hint=auto" > ~/.config/brave-flags.conf

echo -e "${GREEN}◈ Installation Complete!${NC}"
echo -e "${BLUE}Please restart your session or reload Hyprland (SUPER+X to switch themes).${NC}"
