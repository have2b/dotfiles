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
alias q="quarkus"

# Shell integrations - MOVE these BEFORE fzf-tab initialization
eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

# IMPORTANT: fzf-tab must be initialized last or it may conflict
# Remove zinit cdreplay if you're having issues
# zinit cdreplay -q

# Mise
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Quarkus completion (only if installed)
if command -v quarkus >/dev/null 2>&1; then
    source <(quarkus completion)
fi

# ==========================================
# tmux auto-start (safe)
# ==========================================
if command -v tmux >/dev/null 2>&1; then
    if [[ -z "$TMUX" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" ]]; then
        tmux attach -t main 2>/dev/null || tmux new -s main
    fi
fi

autoload -U +X bashcompinit && bashcompinit