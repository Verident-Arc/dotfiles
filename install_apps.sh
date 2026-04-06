#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ◈ Application Installer (System Snapshot)
# ------------------------------------------------------------------------------

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}◈ Starting System Application Snapshot Restoration...${NC}"

# Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing Yay...${NC}"
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd -
fi

# 1. Native Repository Packages
REPO_PKGS=(
$(cat /tmp/pkg_repo.txt)
)

# 2. AUR Packages
AUR_PKGS=(
$(cat /tmp/pkg_aur.txt)
)

echo -e "${BLUE}◈ Installing Repository Packages (${#REPO_PKGS[@]})...${NC}"
sudo pacman -S --needed --noconfirm "${REPO_PKGS[@]}"

echo -e "${BLUE}◈ Installing AUR Packages (${#AUR_PKGS[@]})...${NC}"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

echo -e "${GREEN}◈ All applications have been re-installed!${NC}"
