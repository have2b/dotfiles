#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${SUDO_USER:-}" ]]; then
  ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
  ACTUAL_HOME=$HOME
fi

DOTFILES_REPO="$ACTUAL_HOME/main/dotfiles"
DOTFILES_DIR="~$ACTUAL_HOME/.config"

# For the sddm
SDDM_CONF_DIR="/etc/sddm.conf.d"
SDDM_THEME_DIR="/usr/share/sddm/themes"

log() {
  echo "[INFO] $1"
}

error() {
  echo "[ERROR] $1"
  exit 1
}

check_command() {
  command -v "$1" >/dev/null 2>&1 || error "$1 is not installed."
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    error "Run this script with sudo."
  fi
}

install_package() {
  local pkg=$1
  if pacman -Qi "$pkg" >/dev/null 2>&1; then
    log "$pkg already installed"
  else
    log "Installing $pkg"
    pacman -S --noconfirm "$pkg"
  fi
}

install_packages() {
  local to_install=()

  for pkg in "$@"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>$1; then
      to_install+=("$pkg")
    else
      log "$pkg already installed"
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    log "Installing: ${to_install[*]}"
    pacman -S --noconfirm "${to_install[@]}"
  fi
}

# Setup SDDM
setup_sddm() {
  log "Setting up SDDM"
  mkdir -p "$SDDM_CONF_DIR"
  cat > "$SDDM_CONF_DIR/theme.conf" << EOF
  [Theme]
  Current=void
EOF
  cp -r $DOTFILES_REPO/void/ $SDDM_THEME_DIR
  chmod 644 "$SDDM_CONF_DIR/theme.conf"
  systemctl enable sddm.service
}

setup_hyprland() {
  # Install core packages
  install_packages unzip zip tar zoxide eza zsh jq grim slurp cliphist wl-clipboard
  # Install app packages
  install_packages kitty mako firefox yazi
  # Install hypr ecosystem
  install_packages hyprland hyprlock hyprpaper hyprlauncher
}

main() {
  check_root
  install_package sddm
  setup_sddm
  setup_hyprland

  log "Setup completed"
}

main
