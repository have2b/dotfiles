#!/usr/bin/env bash
set -euo pipefail

########################################
# Colors
########################################
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[0;36m"
RESET="\033[0m"

########################################
# Logging
########################################
log() {
  echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1"
  exit 1
}

section() {
  echo
  echo -e "${CYAN}========== $1 ==========${RESET}"
}

########################################
# Locate dotfiles repo from script path
########################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="$(dirname "$SCRIPT_DIR")"

########################################
# Detect / create actual user
########################################
if [[ -n "${SUDO_USER:-}" ]]; then
  ACTUAL_USER="$SUDO_USER"
  ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  ACTUAL_USER="$USER"
  ACTUAL_HOME="$HOME"
fi

CONFIG_DIR="$ACTUAL_HOME/.config"
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_THEME_DIR="/usr/share/sddm/themes"

########################################
# Checks
########################################
check_root() {
  [[ $EUID -eq 0 ]] || error "Run this script with sudo or as root."
}

check_command() {
  command -v "$1" >/dev/null 2>&1 || error "$1 is not installed."
}

########################################
# Install packages
########################################
install_packages() {
  local to_install=()

  for pkg in "$@"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
      log "$pkg already installed"
    else
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -gt 0 ]]; then
    log "Installing packages: ${to_install[*]}"
    dnf install -y "${to_install[@]}"
    success "Package installation completed"
  fi
}

########################################
# Safe service enable (non-fatal)
########################################
enable_service() {
  local svc="$1"
  if systemctl enable "$svc" 2>/dev/null; then
    log "Enabled $svc"
  else
    warn "$svc not available, skipping"
  fi
}

########################################
# Create a regular user if only root exists
########################################
ensure_regular_user() {
  if [[ "$ACTUAL_USER" != "root" ]]; then
    log "Target user: $ACTUAL_USER"
    return
  fi

  local regular_user
  regular_user=$(awk -F: '$3 >= 1000 && $3 != 65534 && $1 != "root" {print $1; exit}' /etc/passwd)

  if [[ -n "$regular_user" ]]; then
    ACTUAL_USER="$regular_user"
    ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
    log "Detected regular user: $ACTUAL_USER"
    return
  fi

  local new_user="${SETUP_USER:-user}"
  section "CREATING REGULAR USER"

  log "Creating user: $new_user"
  useradd -m -G wheel -s /bin/bash "$new_user"

  if [[ -t 0 ]]; then
    log "Set a password for $new_user"
    passwd "$new_user"
  else
    echo "$new_user:$new_user" | chpasswd
    warn "Set default password 'user' for $new_user — change it on first login."
  fi

  ACTUAL_USER="$new_user"
  ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
  CONFIG_DIR="$ACTUAL_HOME/.config"
  success "Created user $ACTUAL_USER"
}

########################################
# Enable COPR repositories
########################################
setup_copr_repos() {
  section "ENABLING COPR REPOSITORIES"

  install_packages dnf-plugins-core

  log "Enabling yalter/niri (niri compositor)"
  dnf copr enable -y yalter/niri

  log "Enabling errornointernet/quickshell"
  dnf copr enable -y errornointernet/quickshell

  log "Enabling solopasha/hyprland (hyprlock)"
  dnf copr enable -y solopasha/hyprland

  log "Enabling atim/starship"
  dnf copr enable -y atim/starship

  log "Enabling alternateved/eza"
  dnf copr enable -y alternateved/eza

  log "Enabling atim/lazydocker"
  dnf copr enable -y atim/lazydocker

  success "COPR repositories enabled"
}

########################################
# Add Docker CE repository
########################################
setup_docker_repo() {
  log "Adding Docker CE repository"

  if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
    log "Docker CE repository already present"
  else
    dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  success "Docker CE repository ready"
}

########################################
# Setup iwd as NetworkManager Wi-Fi backend
########################################
setup_iwd() {
  section "SETTING UP IWD / NETWORKMANAGER"

  install_packages NetworkManager NetworkManager-wifi iwd

  mkdir -p /etc/NetworkManager
  cat >/etc/NetworkManager/NetworkManager.conf <<EOF
[main]
plugins=keyfile

[device]
wifi.backend=iwd
EOF

  enable_service NetworkManager.service
  enable_service iwd.service

  success "iwd / NetworkManager configured"
}

########################################
# Setup SDDM with auto-login into niri
########################################
setup_sddm() {
  section "SETTING UP SDDM"

  install_packages sddm rsync

  mkdir -p "$SDDM_CONF_DIR"
  mkdir -p "$SDDM_THEME_DIR/void"

  cat >"$SDDM_CONF_DIR/theme.conf" <<EOF
[Theme]
Current=void
EOF

  cat >"$SDDM_CONF_DIR/autologin.conf" <<EOF
[Autologin]
User=$ACTUAL_USER
Session=niri.desktop
Relogin=false
EOF

  rsync -av "$DOTFILES_REPO/void/" "$SDDM_THEME_DIR/void/"

  chmod 644 "$SDDM_CONF_DIR/theme.conf" "$SDDM_CONF_DIR/autologin.conf"

  enable_service sddm.service

  success "SDDM configured with auto-login for $ACTUAL_USER"
}

########################################
# Setup Niri
########################################
setup_niri() {
  section "SETTING UP NIRI"

  install_packages \
    niri xwayland-satellite \
    xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
    gnome-keyring mesa-dri-drivers mesa-libEGL \
    mako

  enable_service upower.service
  enable_service bluetooth.service

  mkdir -p "$CONFIG_DIR/niri"
  rsync -av "$DOTFILES_REPO/niri/" "$CONFIG_DIR/niri/"
  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$CONFIG_DIR/niri"

  success "Niri setup complete"
}

########################################
# Setup Quickshell (install only, no config copy)
########################################
setup_quickshell() {
  section "SETTING UP QUICKSHELL"

  install_packages \
    quickshell qtsvg qtimageformats qtmultimedia qt5compat

  success "Quickshell installed (config not copied)"
}

########################################
# Setup Rofi, Waybar, Hyprlock
########################################
setup_desktop_tools() {
  section "SETTING UP ROFI / WAYBAR / HYPRLOCK"

  install_packages \
    rofi-wayland waybar hyprlock

  mkdir -p "$CONFIG_DIR/rofi"
  mkdir -p "$CONFIG_DIR/waybar"
  mkdir -p "$CONFIG_DIR/hypr"

  rsync -av "$DOTFILES_REPO/rofi/" "$CONFIG_DIR/rofi/"
  rsync -av "$DOTFILES_REPO/waybar/" "$CONFIG_DIR/waybar/"
  rsync -av "$DOTFILES_REPO/hypr/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"

  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$CONFIG_DIR/rofi" "$CONFIG_DIR/waybar" "$CONFIG_DIR/hypr"

  success "Desktop tools configured"
}

########################################
# Setup ZSH
########################################
setup_zsh() {
  section "SETTING UP ZSH"

  install_packages zsh git starship zoxide eza

  ANTIDOTE_HOME="${ACTUAL_HOME}/.local/share/antidote"
  ZSH_PLUGIN_FILE="${ANTIDOTE_HOME}/.zsh_plugins.txt"

  mkdir -p "$ANTIDOTE_HOME"
  mkdir -p "$ACTUAL_HOME/.local/share/zoxide"

  if [[ ! -d "$ANTIDOTE_HOME/.git" ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
  fi

  rsync -av "$DOTFILES_REPO/zsh/antidote.zshrc" "$ACTUAL_HOME/.zshrc"
  rsync -av "$DOTFILES_REPO/zsh/.zsh_plugins.txt" "$ZSH_PLUGIN_FILE"

  ZSH_PATH="$(command -v zsh)"
  if grep -q "$ZSH_PATH" /etc/shells; then
    chsh -s "$ZSH_PATH" "$ACTUAL_USER"
  else
    warn "$ZSH_PATH not in /etc/shells, skipping chsh"
  fi

  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$ACTUAL_HOME/.local" "$ACTUAL_HOME/.zshrc"

  success "Zsh setup complete"
}

########################################
# Setup tmux
########################################
setup_tmux() {
  section "SETTING UP TMUX"

  install_packages tmux git

  local tpm_dir="$ACTUAL_HOME/.tmux/plugins/tpm"

  if [[ -d "$tpm_dir" ]]; then
    log "TPM already installed"
  else
    log "Installing TPM (Tmux Plugin Manager)"
    sudo -u "$ACTUAL_USER" git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  mkdir -p "$CONFIG_DIR/tmux"
  rsync -av "$DOTFILES_REPO/tmux/" "$CONFIG_DIR/tmux/"
  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$CONFIG_DIR/tmux" "$tpm_dir"

  success "tmux setup complete"
}

########################################
# Misc tools
########################################
setup_misc() {
  section "INSTALLING MISC TOOLS"

  install_packages \
    fastfetch btop lazygit lazydocker \
    which flatpak pavucontrol \
    pipewire wireplumber playerctl brightnessctl \
    openssh fcitx5 fcitx5-qt fcitx5-bamboo fcitx5-configtool

  success "Misc tools installed"
}

########################################
# Git setup (runs as actual user)
########################################
setup_git() {
  section "GIT SETUP"

  sudo -u "$ACTUAL_USER" git config --global user.email "thanhlongvu156@gmail.com"
  sudo -u "$ACTUAL_USER" git config --global user.name "have2b"
  sudo -u "$ACTUAL_USER" git config --global core.pager "cat"

  success "Git setup completed"
}

########################################
# Copy configuration
########################################
copy_config() {
  section "SYNCING CONFIGURATION FILES"

  mkdir -p "$CONFIG_DIR"

  rsync -av "$DOTFILES_REPO/alacritty" "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/tmux" "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/fastfetch" "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/nvim" "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/starship/starship.toml" "$CONFIG_DIR"

  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$CONFIG_DIR"

  success "Configuration files installed"
}

########################################
# Install Docker
########################################
install_docker() {
  section "INSTALLING DOCKER"

  setup_docker_repo

  install_packages \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin

  log "Enabling Docker service"
  systemctl enable --now docker.service

  log "Adding $ACTUAL_USER to docker group"
  usermod -aG docker "$ACTUAL_USER"

  success "Docker installed and configured"
}

########################################
# Install fonts
########################################
install_fonts() {
  section "INSTALLING FONTS"

  install_packages \
    jetbrains-mono-fonts-all \
    google-noto-sans-fonts google-noto-cjk-fonts google-noto-emoji-fonts

  success "Fonts installed"
}

########################################
# Main
########################################
main() {
  section "FEDORA SYSTEM SETUP WITH NIRI"

  check_root

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    error "Dotfiles repo not found at $DOTFILES_REPO"
  fi

  ensure_regular_user

  setup_copr_repos
  setup_iwd
  setup_sddm
  setup_niri
  setup_quickshell
  setup_desktop_tools
  setup_zsh
  setup_misc
  setup_tmux
  install_docker
  copy_config
  setup_git
  install_fonts

  section "SETUP COMPLETE"
  success "System setup completed successfully"
  warn "Log out and back in for group changes (docker) and shell change (zsh) to take effect."
}

main
