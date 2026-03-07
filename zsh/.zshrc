# ==========================================
# Zinit Setup
# ==========================================
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# ==========================================
# Shell Options
# ==========================================
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt EXTENDED_HISTORY
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS

# ==========================================
# History
# ==========================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000

# ==========================================
# Completion System (fast init)
# ==========================================
autoload -Uz compinit
compinit -C

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ==========================================
# Prompt (fast)
# ==========================================
eval "$(starship init zsh)"

# ==========================================
# Core tool integrations
# ==========================================
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# ==========================================
# Zinit Plugins (async)
# ==========================================

# Syntax highlighting must load early
zinit ice wait=0 lucid
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Completions
zinit ice wait lucid
zinit light zsh-users/zsh-completions

# fzf-tab
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# command usage helper
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

# OMZ snippets
zinit ice wait lucid
zinit snippet OMZP::sudo
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# ==========================================
# fzf-tab configuration
# ==========================================
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'

zstyle ':fzf-tab:complete:cd:*' fzf-preview \
'eza -1 --color=always $realpath'

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags \
'--height=40% --border --preview-window=right:60%'

# ==========================================
# Keybindings
# ==========================================
bindkey -e

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

bindkey '^I' fzf-tab-complete

# ==========================================
# Environment
# ==========================================
export PATH="$HOME/.cargo/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] \
  && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Mise
eval "$("$HOME/.local/bin/mise" activate zsh)"

# Quarkus
source <(quarkus completion)

# ==========================================
# Aliases
# ==========================================
alias ls='eza'
alias ll='eza -alF'
alias la='eza -A'

alias ff='fastfetch'
alias c='clear'

alias lzg='lazygit'
alias lzd='lazydocker'

alias update='sudo pacman -Syu'

alias warpc='warp-cli connect'
alias warpdc='warp-cli disconnect'

alias q='quarkus'

# ==========================================
# tmux auto-start (safe)
# ==========================================
if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" ]]; then
    tmux attach -t main 2>/dev/null || tmux new -s main
fi

# ==========================================
# Bash compatibility
# ==========================================
autoload -U +X bashcompinit && bashcompinit
