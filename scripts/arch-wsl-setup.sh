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
  echo -e "${RED}[ERROR]${RESET} $1" >&2
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
  ACTUAL_USER="${USER:-$(id -un)}"
  ACTUAL_HOME="${HOME:-$(getent passwd "$ACTUAL_USER" | cut -d: -f6)}"
fi

ACTUAL_GROUP="$(id -gn "$ACTUAL_USER")"
DOTFILES_REPO="$ACTUAL_HOME/main/dotfiles"
CONFIG_DIR="$ACTUAL_HOME/.config"

########################################
# Helpers
########################################
check_root() {
  [[ $EUID -eq 0 ]] || error "Run this script with sudo."
}

# Run a command as the real (non-root) user with their own $HOME
as_user() {
  sudo -u "$ACTUAL_USER" -H "$@"
}

fix_owner() {
  chown -R "$ACTUAL_USER:$ACTUAL_GROUP" "$@"
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
# Update system
########################################
update_system() {
  section "UPDATING SYSTEM"

  # Fresh Arch WSL images ship without an initialized keyring
  if [[ ! -f /etc/pacman.d/gnupg/pubring.gpg && ! -f /etc/pacman.d/gnupg/pubring.kbx ]]; then
    log "Initializing pacman keyring"
    pacman-key --init
    pacman-key --populate archlinux
  fi

  pacman -Sy --noconfirm --needed archlinux-keyring
  pacman -Su --noconfirm

  success "System updated"
}

########################################
# Setup ZSH (zinit)
########################################
setup_zsh() {
  section "SETTING UP ZSH"

  install_packages zsh git rsync

  # Must match ZINIT_HOME in zsh/zinit.zshrc
  local zinit_home="${ACTUAL_HOME}/.local/share/zinit/zinit.git"

  as_user mkdir -p "$ACTUAL_HOME/.local/share/zoxide" "$(dirname "$zinit_home")"

  if [[ ! -d "$zinit_home/.git" ]]; then
    log "Installing zinit"
    as_user git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$zinit_home"
  else
    log "zinit already installed"
  fi

  rsync -av "$DOTFILES_REPO/zsh/zinit.zshrc" "$ACTUAL_HOME/.zshrc"

  local zsh_path
  zsh_path="$(command -v zsh)"
  if grep -qx "$zsh_path" /etc/shells; then
    chsh -s "$zsh_path" "$ACTUAL_USER"
  else
    warn "$zsh_path not in /etc/shells, skipping chsh"
  fi

  fix_owner "$ACTUAL_HOME/.local" "$ACTUAL_HOME/.zshrc"

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
    as_user git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  # TPM installs plugins into ~/.tmux/plugins, so the whole tree must be user-owned
  fix_owner "$ACTUAL_HOME/.tmux"

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

  # The docker group exists once the package is installed, regardless of systemd
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
    warn "Alternatively, use Docker Desktop's WSL integration."
  fi
}

########################################
# Install paru (AUR helper)
########################################
# makepkg refuses to run as root, so we create a temporary unprivileged
# builder user, run the build as that user, then tear it down.
PARU_BUILDER_USER="paru-builder"
PARU_TMP_DIR=""

cleanup_paru_builder() {
  rm -f "/etc/sudoers.d/${PARU_BUILDER_USER}"
  if id "$PARU_BUILDER_USER" >/dev/null 2>&1; then
    userdel -r "$PARU_BUILDER_USER" 2>/dev/null || true
  fi
  if [[ -n "$PARU_TMP_DIR" ]]; then
    rm -rf "$PARU_TMP_DIR"
  fi
}

install_paru() {
  section "INSTALLING PARU"

  if command -v paru >/dev/null 2>&1; then
    log "paru already installed"
    return
  fi

  install_packages base-devel git sudo

  # Tear down the builder even if the build fails part-way
  trap cleanup_paru_builder EXIT

  if ! id "$PARU_BUILDER_USER" >/dev/null 2>&1; then
    log "Creating temporary builder user: $PARU_BUILDER_USER"
    useradd -m "$PARU_BUILDER_USER"
  fi

  # Allow the builder to install makepkg -s dependencies (pacman only)
  echo "$PARU_BUILDER_USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" \
    > "/etc/sudoers.d/${PARU_BUILDER_USER}"
  chmod 440 "/etc/sudoers.d/${PARU_BUILDER_USER}"

  PARU_TMP_DIR=$(mktemp -d)
  chown "$PARU_BUILDER_USER:$PARU_BUILDER_USER" "$PARU_TMP_DIR"

  # cd into the build dir first: the builder can't read the caller's cwd
  # (usually inside a 700 home directory), which makes git/makepkg fail.
  log "Cloning paru repository"
  (cd "$PARU_TMP_DIR" && sudo -u "$PARU_BUILDER_USER" -H \
    git clone https://aur.archlinux.org/paru.git .)

  log "Building paru (as $PARU_BUILDER_USER)"
  (cd "$PARU_TMP_DIR" && sudo -u "$PARU_BUILDER_USER" -H \
    makepkg -s --noconfirm)

  log "Installing paru package"
  local pkg
  pkg=$(find "$PARU_TMP_DIR" -maxdepth 1 -name 'paru-*.pkg.tar.*' \
    ! -name 'paru-debug-*' ! -name '*.sig' | head -n 1)
  [[ -n "$pkg" ]] || error "paru package not found after build"
  pacman -U --noconfirm "$pkg"

  log "Removing temporary builder user"
  cleanup_paru_builder
  trap - EXIT

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
  # starship reads ~/.config/starship.toml by default
  rsync -av "$DOTFILES_REPO/starship/starship.toml" "$CONFIG_DIR/"

  fix_owner "$CONFIG_DIR"

  success "Configuration files installed"
}

########################################
# Git setup
########################################
setup_git() {
  section "GIT SETUP"

  # Run as the real user so this lands in their ~/.gitconfig, not /root's
  as_user git config --global user.email "thanhlongvu156@gmail.com"
  as_user git config --global user.name "have2b"
  as_user git config --global core.pager "cat"

  success "Git setup completed"
}

########################################
# Main
########################################
main() {
  section "ARCH WSL TERMINAL SETUP"

  check_root

  if [[ "$ACTUAL_USER" == "root" ]]; then
    warn "Running for the root user. Create a regular user and run this with sudo from that user to set up their environment instead."
  fi

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    error "Dotfiles repo not found at $DOTFILES_REPO"
  fi

  update_system
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
