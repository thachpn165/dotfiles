if [[ -o interactive ]]; then
  # Shift+Enter inserts a newline instead of executing the command.
  function _insert_newline() { LBUFFER+=$'\n'; }
  zle -N _insert_newline
  bindkey '\e[13;2u' _insert_newline

  # Show a lightweight welcome only for top-level interactive shells.
  if [[ "${DOTFILES_WELCOME:-1}" != "0" ]] && [[ "${SHLVL:-1}" -le 1 ]]; then
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

  if command -v fast-theme &>/dev/null; then
    fast-theme "$ZSH_CUSTOM/themes/fast-syntax-highlighting-catppuccin-mocha.ini" &>/dev/null
  fi
fi
