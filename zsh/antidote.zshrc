# =========================
# Antidote bootstrap
# =========================
ANTIDOTE_HOME="${HOME}/.local/share/antidote"
zsh_plugins=${ANTIDOTE_HOME:-~/.local/share/antidote}/.zsh_plugins

# Install Antidote if not already installed
if [ ! -d "$ANTIDOTE_HOME" ]; then
    mkdir -p "$(dirname "$ANTIDOTE_HOME")"
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${ANTIDOTE_HOME}"
fi

source "${ANTIDOTE_HOME}/antidote.zsh"
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

fpath=("${ANTIDOTE_HOME}/functions" $fpath)
autoload -Uz antidote

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Source your static plugins file.
source ${zsh_plugins}.zsh

# =========================
# Starship (manual)
# =========================
eval "$(starship init zsh)"

# =========================
# Completion system
# =========================
autoload -Uz compinit && compinit

# =========================
# Keybindings
# =========================
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

# =========================
# History
# =========================
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory
setopt hist_ignore_space hist_ignore_all_dups
setopt hist_save_no_dups hist_ignore_dups hist_find_no_dups

# =========================
# Completion styling
# =========================
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# =========================
# fzf-tab config
# =========================
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' fzf-flags --height=40% --border --preview-window=right:60%

# =========================
# Aliases
# =========================
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
alias q="quarkus"

# =========================
# Integrations
# =========================
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# Mise
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Quarkus completion
if command -v quarkus >/dev/null 2>&1; then
    source <(quarkus completion)
fi

# =========================
# tmux auto-start
# =========================
if command -v tmux >/dev/null 2>&1; then
    if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" ]]; then
        tmux attach -t main 2>/dev/null || tmux new -s main
    fi
fi

autoload -U +X bashcompinit && bashcompinit