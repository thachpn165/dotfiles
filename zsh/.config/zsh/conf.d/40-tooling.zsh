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

if command -v fzf &>/dev/null; then
  # `fzf --zsh` emits harmless `zle` warnings for `zsh -ic '...'` shells.
  # Skip that path for command-string shells so startup stays quiet in automation.
  if [[ -z "${ZSH_EXECUTION_STRING:-}" ]]; then
    source <(fzf --zsh)
  fi
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

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

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi
