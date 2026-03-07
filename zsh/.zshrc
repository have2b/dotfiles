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
# Completion System
# ==========================================
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ==========================================
# Prompt
# ==========================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ==========================================
# Core Tools
# ==========================================
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
fi

# ==========================================
# Zinit Plugins
# ==========================================

# Syntax highlighting (load early)
zinit ice wait=0 lucid
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Extra completions
zinit ice wait lucid
zinit light zsh-users/zsh-completions

# fzf-tab (must load after compinit)
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# command helper
zinit ice wait lucid
zinit light MichaelAquilina/zsh-you-should-use

# OMZ snippets
zinit ice wait lucid
zinit snippet OMZP::sudo
zinit snippet OMZP::git
zinit snippet OMZP::command-not-found

# ==========================================
# fzf-tab Configuration
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

# ==========================================
# Environment
# ==========================================
export PATH="$HOME/.cargo/bin:$PATH"

# Mise
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Quarkus completion (only if installed)
if command -v quarkus >/dev/null 2>&1; then
    source <(quarkus completion)
fi

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
if command -v tmux >/dev/null 2>&1; then
    if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" ]]; then
        tmux attach -t main 2>/dev/null || tmux new -s main
    fi
fi

# ==========================================
# Bash compatibility
# ==========================================
autoload -U +X bashcompinit && bashcompinit