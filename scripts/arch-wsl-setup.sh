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
# Check whether systemd is managing services
########################################
systemd_is_active() {
  [[ "$(ps -p 1 -o comm= 2>/dev/null || true)" == "systemd" ]] \
    && [[ "$(systemctl is-system-running 2>/dev/null || true)" != "offline" ]]
}

########################################
# Safe service enable (non-fatal)
########################################
enable_service() {
  local svc="$1"
  if systemd_is_active; then
    if systemctl enable "$svc" 2>/dev/null; then
      log "Enabled $svc"
    else
      warn "$svc not available, skipping"
    fi
  else
    warn "systemd not active (WSL default) — skipping enable of $svc"
  fi
}

########################################
# Setup ZSH
########################################
setup_zsh() {
  section "SETTING UP ZSH"

  install_packages zsh git rsync

  local antidote_home="${ACTUAL_HOME}/.local/share/antidote"
  local zsh_plugin_file="${antidote_home}/.zsh_plugins.txt"

  mkdir -p "$antidote_home"
  mkdir -p "$ACTUAL_HOME/.local/share/zoxide"

  if [[ ! -d "$antidote_home/.git" ]]; then
    log "Installing Antidote"
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_home"
  fi

  rsync -av "$DOTFILES_REPO/zsh/antidote.zshrc" "$ACTUAL_HOME/.zshrc"
  rsync -av "$DOTFILES_REPO/zsh/.zsh_plugins.txt" "$zsh_plugin_file"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if grep -q "$zsh_path" /etc/shells; then
    chsh -s "$zsh_path" "$ACTUAL_USER"
  else
    warn "$zsh_path not in /etc/shells, skipping chsh"
  fi

  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" \
    "$ACTUAL_HOME/.local" "$ACTUAL_HOME/.zshrc"

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
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
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
    fastfetch btop lazygit lazydocker which openssh \
    jq fzf zoxide eza yazi unzip zip tar starship rsync git

  success "Misc tools installed"
}

########################################
# Install Docker
########################################
install_docker() {
  section "INSTALLING DOCKER"

  install_packages docker

  if systemd_is_active; then
    log "Enabling Docker service"
    systemctl enable --now docker.service
    log "Adding $ACTUAL_USER to docker group"
    usermod -aG docker "$ACTUAL_USER"
    success "Docker installed and configured"
  else
    warn "systemd is not active — docker.service not enabled."
    warn "To enable systemd in WSL, add the following to /etc/wsl.conf then run 'wsl --shutdown' from Windows:"
    warn "  [boot]"
    warn "  systemd=true"
    warn "After rebooting WSL, run: sudo systemctl enable --now docker.service"
    warn "Alternatively, use Docker Desktop's WSL integration."
  fi
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

  local tmp_dir
  tmp_dir=$(mktemp -d)

  log "Cloning paru repository"
  git clone https://aur.archlinux.org/paru.git "$tmp_dir"

  log "Building paru"
  bash -c "cd \"$tmp_dir\" && makepkg -s --noconfirm"

  log "Installing paru package"
  pacman -U --noconfirm "$tmp_dir"/paru-*.pkg.tar.zst

  rm -rf "$tmp_dir"

  success "paru installed"
}

########################################
# Copy configuration
########################################
copy_config() {
  section "SYNCING CONFIGURATION FILES"

  mkdir -p "$CONFIG_DIR"

  rsync -av "$DOTFILES_REPO/tmux"      "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/nvim"      "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/fastfetch" "$CONFIG_DIR"
  mkdir -p "$CONFIG_DIR/starship"
  rsync -av "$DOTFILES_REPO/starship/starship.toml" "$CONFIG_DIR/starship/"

  chown -R "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$CONFIG_DIR"

  success "Configuration files installed"
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
# Main
########################################
main() {
  section "ARCH WSL TERMINAL SETUP"

  check_root

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    error "Dotfiles repo not found at $DOTFILES_REPO"
  fi

  setup_zsh
  setup_misc
  setup_tmux
  install_docker
  install_paru
  copy_config
  setup_git

  section "SETUP COMPLETE"
  success "WSL terminal setup completed successfully"
  warn "Restart your shell (or run 'wsl --shutdown' from Windows) for the zsh shell and docker group changes to take effect."
}

main
