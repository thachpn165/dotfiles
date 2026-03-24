# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="amuse"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  fast-syntax-highlighting
)

# Make autosuggestions readable on translucent terminal backgrounds.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#a6adc8'

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Shift+Enter inserts newline instead of executing command
function _insert_newline() { LBUFFER+=$'\n'; }
zle -N _insert_newline
bindkey '\e[13;2u' _insert_newline

# Welcome screen (interactive shells only)
# Disable by setting: DOTFILES_WELCOME=0
if [[ -o interactive ]] && [[ "${DOTFILES_WELCOME:-1}" != "0" ]] && [[ "${SHLVL:-1}" -le 1 ]]; then
  if command -v fastfetch &>/dev/null; then
    if [[ -f "$HOME/.config/fastfetch/config.jsonc" ]]; then
      fastfetch --config "$HOME/.config/fastfetch/config.jsonc"
    else
      fastfetch
    fi
    print -P "%F{cyan}Tips:%f  %F{magenta}WezTerm%f leader %B^A%b  |  %B^A g%b SSH picker  |  %B^A N%b notes  |  %B^A ?%b help"
    print -P "       %F{magenta}Neovim%f  %B<leader>oN%b new note in folder  |  %B<leader>oo%b open in Obsidian"
  fi
fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
if [[ -d "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach" ]]; then
  alias cdobs="cd '$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach'"
fi
alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'

# yazi file manager
if command -v yazi &>/dev/null; then
  yy() {
    local tmp cwd
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp" 2>/dev/null)" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
      builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
  alias y="yy"
fi

# eza (modern ls replacement)
if command -v eza &>/dev/null; then
  export EZA_DEFAULTS="--group-directories-first --icons=auto"
  alias ls="eza $EZA_DEFAULTS"
  alias l="eza $EZA_DEFAULTS"
  alias ll="eza $EZA_DEFAULTS -lah"
  alias la="eza $EZA_DEFAULTS -la"
  alias lt="eza $EZA_DEFAULTS -T -L 2"
  alias ltt="eza $EZA_DEFAULTS -T -L 4"
  alias lg="eza $EZA_DEFAULTS -lah --git"
fi


# Added by Windsurf
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"


# Herd injected NVM configuration
export NVM_DIR="$HOME/Library/Application Support/Herd/config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

[[ -f "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh" ]] && builtin source "/Applications/Herd.app/Contents/Resources/config/shell/zshrc.zsh"

# Herd injected PHP binary.
export PATH="$HOME/Library/Application Support/Herd/bin/":$PATH

# Python aliases - use Homebrew Python 3.13
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

# Load local secrets (API keys, etc.) - not tracked by git
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# fast-syntax-highlighting theme (Catppuccin Mocha)
if command -v fast-theme &>/dev/null; then
  fast-theme ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/fast-syntax-highlighting-catppuccin-mocha.ini &>/dev/null
fi

# fzf - fuzzy finder (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

  # Ctrl+T preview: directories with eza (if available), files with bat/batcat (if available)
  _fzf_preview_cmd='
    if [[ -d {} ]]; then
      if command -v eza &>/dev/null; then
        eza --tree --level=2 --group-directories-first --icons=auto {}
      else
        ls -la {}
      fi
    else
      if command -v bat &>/dev/null; then
        bat --style=numbers --color=always --line-range :300 {}
      elif command -v batcat &>/dev/null; then
        batcat --style=numbers --color=always --line-range :300 {}
      else
        sed -n "1,300p" {}
      fi
    fi
  '
  export FZF_CTRL_T_OPTS="--preview '$_fzf_preview_cmd' --preview-window=right,60%,border-left,wrap"
fi

# zoxide - smart cd (use 'z' instead of 'cd')
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Tab behavior with zsh-autosuggestions:
# - If a suggestion is visible, Tab accepts it.
# - Otherwise, Tab falls back to the current Tab widget (e.g. fzf-completion).
if [[ -o interactive ]] && (( ${+widgets[autosuggest-accept]} )); then
  typeset -g DOTFILES_TAB_FALLBACK_WIDGET
  DOTFILES_TAB_FALLBACK_WIDGET="${${(z)$(bindkey '^I')}[2]}"
  if [[ -z "$DOTFILES_TAB_FALLBACK_WIDGET" || "$DOTFILES_TAB_FALLBACK_WIDGET" == "_tab_accept_suggestion_or_complete" ]]; then
    DOTFILES_TAB_FALLBACK_WIDGET="expand-or-complete"
  fi

  _tab_accept_suggestion_or_complete() {
    if [[ -n "${POSTDISPLAY:-}" ]]; then
      zle autosuggest-accept
    else
      zle "$DOTFILES_TAB_FALLBACK_WIDGET"
    fi
  }
  zle -N _tab_accept_suggestion_or_complete
  bindkey '^I' _tab_accept_suggestion_or_complete
fi
