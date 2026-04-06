# ◈ GEMINI.md - Workspace Context ◈

This directory (`/home/_null`) is a specialized **Arch Linux (CachyOS) Personal Workspace**, heavily optimized for the **Hyprland** tiling window manager. It features a modular configuration, dynamic theme generation via Matugen, and dotfile management through GNU Stow.

## 📂 Key Projects & Directories

- **`~/dotfiles`**: The primary source of truth for system configurations.
  - **`config/`**: Contains modular configs for `hypr`, `waybar`, `kitty`, `rofi`, `yazi`, etc.
  - **`home/`**: Home-level dotfiles like `.zshrc`, `.bashrc`, and `.p10k.zsh`.
  - **`install.sh`**: A master script that installs dependencies via `paru` and symlinks configs using `stow`.
- **`~/Arch-Hyprland`**: A local clone of JaKooLit's Hyprland installation framework, used as a foundation for the environment.
- **`~/.config/hypr`**: The active Hyprland configuration directory.
  - **`modules/`**: Modularized settings (monitors, binds, rules, animations, etc.).
  - **`scripts/`**: Utility scripts for screenshots, locking, volume, and workspace management.
- **`~/Vencord`**: Source and configuration for the Vencord Discord client modification.
- **`~/.oh-my-zsh`**: Shell enhancement framework with custom plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`).

## 🛠️ Key Files & Components

- **`~/.zshrc`**: Features a sophisticated `fetch` function that dynamically generates Fastfetch configurations using **Matugen** color palettes extracted from the current wallpaper.
- **`~/dotfiles/install.sh`**: Handles full system bootstrapping, including AUR helper (`paru`) setup, package installation, and stow-based linking.
- **`~/.config/hypr/hyprland.conf`**: The main entry point that sources modular configs from `~/.config/hypr/modules/`.
- **`~/.config/hypr/modules/settings.conf`**: Contains core compositor settings (gaps, borders, input, gestures).

## 🚀 Workflows & Usage

### Dotfile Management
Configurations should be modified within `~/dotfiles` and then deployed using:
```bash
cd ~/dotfiles
stow -v -d config -t ~/.config .
```

### System Updates & Installation
To synchronize the system with the defined state:
```bash
cd ~/dotfiles
./install.sh
```

### Visual Styling
The workspace uses a "Material You" approach for Linux:
1. Wallpapers are stored in `~/Images/Wallpapers`.
2. **Matugen** parses the wallpaper to generate color schemes.
3. Custom scripts (e.g., in `~/.config/hypr/scripts/quickshell/`) propagate these colors to UI components like Fastfetch and Waybar.

## 🔧 Technical Standards

- **Modularization**: Hyprland configs are split by concern (e.g., `keybinds.conf`, `rules.conf`) for maintainability.
- **AMD Optimization**: Environment variables in `env.conf` are tuned for AMD GPUs (`radeonsi`, `RADV`).
- **Performance**: Variable Frame Rate (VFR) is enabled; hardware cursors are managed via `no_hardware_cursors = 2`.
- **Safety**: Configuration changes should be validated with `hyprctl configerrors` before finalizing.

## 📝 TODO / Maintenance
- [ ] Complete the migration of all standalone configs into the `~/dotfiles` stow structure.
- [ ] Refine the transition between Zsh and Fish as primary shells (currently both are partially configured).
