if [[ -d "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach" ]]; then
  alias cdobs="cd '$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach'"
fi

alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'

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
