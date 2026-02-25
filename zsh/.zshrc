# These config requires git, eza, nvm, bun, fzf, zoxide, lazydocker and lazygit
# Install before using this config
# Zinit home directory where we will store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# If Zinit not installed, then install it
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Loading theme
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Adding plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use

# Adding snippets
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
zinit snippet OMZP::git

# Load completions FIRST - This should come before any completion-related settings
autoload -Uz compinit && compinit

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey "^[[H" beginning-of-line    # Home
bindkey "^[[F" end-of-line         # End
bindkey "^[[1;5C" forward-word     # Ctrl + Right
bindkey "^[[1;5D" backward-word    # Ctrl + Left
bindkey '^I' fzf-tab-complete  # Make sure Tab is bound to fzf-tab

# History for zsh and tmux
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling - FIXED: Removed 'menu no' which disables menu completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select  # Changed from 'no' to 'select' for menu completion

# fzf-tab configuration
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# fzf-tab default options
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags --height=40% --border --preview-window=right:60%

# Export eza because it is no longer supported
export PATH="$HOME/.cargo/bin:$PATH"

# Aliases
alias ff='fastfetch'
alias ls='eza'
alias ll='eza -alF'
alias la='eza -A'
alias c='clear'
alias lzd='lazydocker'
alias lzg='lazygit'
alias update='sudo pacman -Syu'
alias warpc='warp-cli connect'
alias warpdc='warp-cli disconnect'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Shell integrations - MOVE these BEFORE fzf-tab initialization
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# IMPORTANT: fzf-tab must be initialized last or it may conflict
# Remove zinit cdreplay if you're having issues
# zinit cdreplay -q

autoload -U +X bashcompinit && bashcompinit


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Always work in a tmux session if Tmux is installed
if which tmux 2>&1 >/dev/null; then
  if [ $TERM != "screen-256color" ] && [  $TERM != "screen" ]; then
    tmux attach -t default || tmux new -s default; exit
  fi
fi
