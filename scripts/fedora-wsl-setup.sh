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

ACTUAL_GROUP="$(id -gn "$ACTUAL_USER")"
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
# Check whether systemd is managing services
########################################
# Reads /proc/1/comm instead of `ps`, since procps-ng may be missing
# on the minimal Fedora WSL image.
systemd_is_active() {
  [[ "$(cat /proc/1/comm 2>/dev/null || true)" == "systemd" ]] \
    && [[ "$(systemctl is-system-running 2>/dev/null || true)" != "offline" ]]
}

########################################
# Setup ZSH (zinit)
########################################
setup_zsh() {
  section "SETTING UP ZSH"

  # util-linux-user provides chsh on Fedora
  install_packages zsh git curl rsync zoxide fzf util-linux-user

  local zinit_home="${ACTUAL_HOME}/.local/share/zinit/zinit.git"

  mkdir -p "$ACTUAL_HOME/.local/share/zoxide"
  chown -R "$ACTUAL_USER:$ACTUAL_GROUP" "$ACTUAL_HOME/.local"

  if [[ -d "$zinit_home/.git" ]]; then
    log "zinit already installed"
  else
    log "Installing zinit"
    sudo -u "$ACTUAL_USER" mkdir -p "$(dirname "$zinit_home")"
    sudo -u "$ACTUAL_USER" git clone --depth=1 \
      https://github.com/zdharma-continuum/zinit.git "$zinit_home"
  fi

  rsync -av "$DOTFILES_REPO/zsh/zinit.zshrc" "$ACTUAL_HOME/.zshrc"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if grep -qx "$zsh_path" /etc/shells; then
    chsh -s "$zsh_path" "$ACTUAL_USER"
  else
    warn "$zsh_path not in /etc/shells, skipping chsh"
  fi

  chown -R "$ACTUAL_USER:$ACTUAL_GROUP" \
    "$ACTUAL_HOME/.local" "$ACTUAL_HOME/.zshrc"

  success "Zsh setup complete"
}

########################################
# Install starship (not in official Fedora repos)
########################################
# Uses the upstream installer, which downloads the prebuilt GitHub release
# binary and verifies its checksum.
install_starship() {
  section "INSTALLING STARSHIP"

  if command -v starship >/dev/null 2>&1; then
    log "starship already installed ($(starship --version | head -n1))"
    return
  fi

  install_packages curl tar

  log "Installing starship to /usr/local/bin via upstream installer"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin

  success "starship installed"
}

########################################
# Setup tmux
########################################
setup_tmux() {
  section "SETTING UP TMUX"

  install_packages tmux git rsync

  local tpm_dir="$ACTUAL_HOME/.tmux/plugins/tpm"

  if [[ -d "$tpm_dir" ]]; then
    log "TPM already installed"
  else
    log "Installing TPM (Tmux Plugin Manager)"
    sudo -u "$ACTUAL_USER" mkdir -p "$(dirname "$tpm_dir")"
    sudo -u "$ACTUAL_USER" git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  mkdir -p "$CONFIG_DIR/tmux"
  rsync -av "$DOTFILES_REPO/tmux/" "$CONFIG_DIR/tmux/"
  chown -R "$ACTUAL_USER:$ACTUAL_GROUP" "$CONFIG_DIR/tmux" "$ACTUAL_HOME/.tmux"

  success "tmux setup complete"
}

########################################
# Misc tools
########################################
setup_misc() {
  section "INSTALLING MISC TOOLS"

  install_packages \
    fastfetch btop which openssh \
    jq unzip zip tar

  success "Misc tools installed"
}

########################################
# Install Docker (Docker CE repo)
########################################
install_docker() {
  section "INSTALLING DOCKER"

  install_packages dnf-plugins-core

  if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
    log "Docker CE repository already present"
  else
    log "Adding Docker CE repository"
    dnf config-manager addrepo \
      --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
  fi

  install_packages \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin

  log "Adding $ACTUAL_USER to docker group"
  usermod -aG docker "$ACTUAL_USER"

  if systemd_is_active; then
    log "Enabling Docker service"
    systemctl enable --now docker.service
    success "Docker installed and configured"
  else
    warn "systemd is not active — docker.service not enabled."
    warn "To enable systemd in WSL, add the following to /etc/wsl.conf then run 'wsl --shutdown' from Windows:"
    warn "  [boot]"
    warn "  systemd=true"
    warn "After restarting WSL, run: sudo systemctl enable --now docker.service"
  fi
}

########################################
# Copy configuration
########################################
copy_config() {
  section "SYNCING CONFIGURATION FILES"

  install_packages rsync

  mkdir -p "$CONFIG_DIR"

  rsync -av "$DOTFILES_REPO/tmux"      "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/nvim"      "$CONFIG_DIR"
  rsync -av "$DOTFILES_REPO/fastfetch" "$CONFIG_DIR"
  # starship reads ~/.config/starship.toml by default (no STARSHIP_CONFIG set)
  rsync -av "$DOTFILES_REPO/starship/starship.toml" "$CONFIG_DIR/starship.toml"

  chown -R "$ACTUAL_USER:$ACTUAL_GROUP" "$CONFIG_DIR"

  success "Configuration files installed"
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
# Main
########################################
main() {
  section "FEDORA WSL TERMINAL SETUP"

  check_root
  check_command dnf

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    error "Dotfiles repo not found at $DOTFILES_REPO"
  fi

  setup_zsh
  install_starship
  setup_misc
  setup_tmux
  install_docker
  copy_config
  setup_git

  section "SETUP COMPLETE"
  success "WSL terminal setup completed successfully"
  warn "Restart your shell (or run 'wsl --shutdown' from Windows) for the zsh shell and docker group changes to take effect."
}

main
