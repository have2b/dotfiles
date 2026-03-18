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
# Detect actual user
########################################
if [[ -n "${SUDO_USER:-}" ]]; then
  ACTUAL_USER="$SUDO_USER"
  ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  ACTUAL_USER="$USER"
  ACTUAL_HOME="$HOME"
fi

DOTFILES_REPO="$ACTUAL_HOME/main/dotfiles"
CONFIG_DIR="$ACTUAL_HOME/.config"

SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_THEME_DIR="/usr/share/sddm/themes"

########################################
# Checks
########################################
check_root() {
  [[ $EUID -eq 0 ]] || error "Run this script with sudo."
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
    if pacman -Qi "$pkg" >/dev/null 2>&1; then
      log "$pkg already installed"
    else
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -gt 0 ]]; then
    log "Installing packages: ${to_install[*]}"
    pacman -S --noconfirm --needed "${to_install[@]}"
    success "Package installation completed"
  fi
}

########################################
# Setup SDDM
########################################
setup_sddm() {
  section "SETTING UP SDDM"

  install_packages sddm rsync

  mkdir -p "$SDDM_CONF_DIR"

  cat >"$SDDM_CONF_DIR/theme.conf" <<EOF
[Theme]
Current=void
EOF

  rsync -av "$DOTFILES_REPO/void/" "$SDDM_THEME_DIR/void/"

  chmod 644 "$SDDM_CONF_DIR/theme.conf"

  systemctl enable sddm.service

  success "SDDM configured"
}

########################################
# Setup Hyprland
########################################
setup_hyprland() {
  section "SETTING UP HYPRLAND"

  install_packages \
    unzip zip tar \
    zoxide eza zsh jq fzf \
    grim slurp cliphist wl-clipboard

  install_packages \
    kitty quickshell firefox yazi

  install_packages \
    hyprland hyprlock hyprpaper

  install_packages upower
  systemctl enable upower.service

  mkdir -p "$CONFIG_DIR/hypr"

  rsync -av "$DOTFILES_REPO/hypr/" "$CONFIG_DIR/hypr/"

  success "Hyprland setup complete"
}

########################################
# Misc tools
########################################
setup_misc() {
  section "INSTALLING MISC TOOLS"

  install_packages \
    fastfetch btop lazygit lazydocker \
    which flatpak pavucontrol bitwarden-cli \
    openssh fcitx5 fcitx5-qt fcitx5-bamboo fcitx5-configtool

  success "Misc tools installed"
}

########################################
# Git setup
########################################
setup_git() {
  section "GIT SETUP"

  git config --global user.email "thanhlongvu156@gmail.com"
  git config --global user.name "have2b"
  git config --global core.pager "cat"

  success "Git setup completed"
}

########################################
# Copy configuration
########################################
copy_config() {
  section "SYNCING CONFIGURATION FILES"

  mkdir -p "$CONFIG_DIR"

  rsync -av "$DOTFILES_REPO/zsh/.zshrc" "$ACTUAL_HOME/.zshrc"

  rsync -av "$DOTFILES_REPO/quickshell" "$ACTUAL_HOME/quickshell"
  rsync -av "$DOTFILES_REPO/kitty/" "$CONFIG_DIR/kitty/"
  rsync -av "$DOTFILES_REPO/fastfetch/" "$CONFIG_DIR/fastfetch/"
  rsync -av "$DOTFILES_REPO/nvim/" "$CONFIG_DIR/nvim/"

  rsync -av "$DOTFILES_REPO/starship/starship.toml" "$CONFIG_DIR/"

  chown -R "$ACTUAL_USER:$(id -gn $ACTUAL_USER)" "$ACTUAL_HOME/.zshrc" "$CONFIG_DIR"

  chsh -s "$(which zsh)" "$ACTUAL_USER"

  success "Configuration files installed"
}

########################################
# Install Docker
########################################
install_docker() {
  section "INSTALLING DOCKER"

  install_packages docker

  log "Enabling Docker service"
  systemctl enable --now docker.service

  log "Adding $ACTUAL_USER to docker group"
  usermod -aG docker "$ACTUAL_USER"

  success "Docker installed and configured"
}

########################################
# Install paru (AUR helper)
########################################
install_paru() {
  section "INSTALLING PARU"

  if command -v paru >/dev/null 2>&1; then
    log "paru already installed"
    return
  fi

  install_packages base-devel git

  local tmp_dir="/tmp/paru-build"

  log "Cloning paru repository"

  sudo -u "$ACTUAL_USER" bash -c "
    rm -rf $tmp_dir
    git clone https://aur.archlinux.org/paru.git $tmp_dir
  "

  log "Building and installing paru"

  sudo -u "$ACTUAL_USER" bash -c "
    cd $tmp_dir
    makepkg -si --noconfirm
  "

  rm -rf "$tmp_dir"

  success "paru installed"
}

########################################
# Main
########################################
main() {
  section "ARCH SYSTEM SETUP WITH HYPRLAND"

  check_root
  check_command pacman
  check_command systemctl

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    error "Dotfiles repo not found at $DOTFILES_REPO"
  fi

  setup_sddm
  setup_hyprland
  setup_misc
  install_docker
  install_paru
  copy_config
  setup_git

  success "System setup completed successfully"
}

main
